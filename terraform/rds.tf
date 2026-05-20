# rds.tf

# =======================================================================
# 1. 데이터베이스 방화벽 (Security Group)
# =======================================================================
resource "aws_security_group" "jpx_db_sg" {
  name        = "jpx-db-security-group"
  description = "Allow MySQL traffic"
  vpc_id      = aws_vpc.jpx_vpc.id # 이 방화벽이 작동할 우리 VPC를 지정

  # [Inbound] 들어오는 트래픽 통제
  ingress {
    description = "MySQL from VPC"
    from_port   = 3306              # MySQL 기본 포트 시작점
    to_port     = 3306              # MySQL 기본 포트 끝점
    protocol    = "tcp"             # 데이터베이스 통신 표준 프로토콜
    cidr_blocks = ["10.0.0.0/16"]   # ⭐ 중요: 외부 인터넷 차단! 오직 우리 VPC 내부 IP들만 찌를 수 있음
  }

  # [Outbound] 나가는 트래픽 통제 (DB가 외부에 먼저 요청 보낼 일은 거의 없으므로 다 열어둠)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"              # -1은 모든 프로토콜(ALL)을 의미
    cidr_blocks = ["0.0.0.0/0"]     # 모든 목적지로 나가는 것을 허용
  }

  tags = { Name = "jpx-db-sg" }
}

# =======================================================================
# 2. RDS 가용성 확보를 위한 서브넷 묶음 (DB Subnet Group)
# =======================================================================
# AWS RDS는 하나가 죽어도 다른 데이터센터에서 살아나야 하므로, 최소 2개 이상의 AZ(가용영역)를 요구함
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.jpx_vpc.id
  cidr_block        = "10.0.3.0/24"       # 아까 만든 private 1번(10.0.2.0)과 안 겹치게 3번 부여
  availability_zone = "ap-northeast-1c"   # 아까 만든방은 도쿄 1a, 이번 방은 도쿄 1c (데이터센터 물리 분리)
  tags              = { Name = "jpx-private-subnet-2" }
}

resource "aws_db_subnet_group" "jpx_db_subnet_grp" {
  name       = "jpx-db-subnet-group"
  # 위에서 만든 두 개의 프라이빗 방(1a, 1c)을 하나의 그룹으로 묶어서 RDS에게 던져줌
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_2.id]
  tags       = { Name = "jpx-db-subnet-group" }
}

# =======================================================================
# 3. 실제 AWS RDS (MySQL) 인스턴스 사양 정의
# =======================================================================
resource "aws_db_instance" "jpx_database" {
  # [스토리지 설정]
  allocated_storage      = 20               # 기본 디스크 용량 20GB (AWS 프리티어 맥스치)
  max_allocated_storage  = 100              # 오토스케일링 맥스치. 데이터 차오르면 자동으로 100GB까지 늘려줌

  # [엔진 설정]
  engine                 = "mysql"          # DB 종류
  engine_version         = "8.0"            # MySQL 상세 버전 (로컬 Docker 환경과 싱크 매칭)
  instance_class         = "db.t4g.micro"   # 서버 가성비 사양 (t4g가 최신 Graviton 아키텍처라 저렴하고 성능 좋음)
  
  # [DB 접속 정보 및 크레덴셜]
  db_name                = "jpx_db"         # 생성과 동시에 자동으로 만들어질 초기 스키마(데이터베이스) 이름
  username               = "admin"          # DB 마스터 계정 ID
  password               = "jpxpass1234!"   # DB 마스터 패스워드 (실무에선 변수 처리 필수)
  
  # [네트워크/보안 맵핑]
  db_subnet_group_name   = aws_db_subnet_group.jpx_db_subnet_grp.name # 위에서 묶은 1a, 1c 프라이빗 방 그룹 지정
  vpc_security_group_ids = [aws_security_group.jpx_db_sg.id]          # 위에서 만든 방화벽(3306 포트 제약) 장착
  
  # [SRE 운영 및 삭제 정책]
  skip_final_snapshot    = true             # 테라폼으로 지울(destroy) 때 백업 스냅샷 안 만들고 바로 빛의 속도로 지우겠다는 뜻
  publicly_accessible    = false            # ⭐ 핵심: true로 주면 퍼블릭 IP가 나와서 털림. false로 줘서 바깥 세상과 완전히 단절.

  tags                   = { Name = "jpx-mysql-rds" }
}