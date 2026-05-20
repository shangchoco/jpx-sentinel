# ec2.tf

# =======================================================================
# 1. AWS 최신 우분투(Ubuntu) AMI ID 자동으로 찾아오기 (Data Source)
# =======================================================================
# 하드코딩된 AMI ID는 리전이 바뀌면 깨집니다. 
# 테라폼 Data Source를 쓰면 항상 도쿄 리전의 최신 공식 우분투 24.04 LTS 이미지 ID를 동적으로 긁어옵니다.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (우분투 공식 공급사 ID)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =======================================================================
# 2. 내 로컬 PC에서 EC2로 접속할 때 쓸 SSH 키페어 생성
# =======================================================================
# 이 코드는 로컬에서 RSA 알고리즘으로 프라이빗/퍼블릭 키를 구운 뒤, 
# 퍼블릭 키를 AWS에 등록하여 "jpx-bastion-key"라는 이름의 키페어로 만들어줍니다.
resource "tls_private_key" "jpx_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jpx_keypair" {
  key_name   = "jpx-bastion-key"
  public_key = tls_private_key.jpx_key.public_key_openssh
}

# (선택) 내 로컬 컴퓨터 폴더에 .pem 개인키 파일 실물로 저장하기
# 이 파일이 있어야 나중에 ssh -i jpx-key.pem ubuntu@... 구조로 접속할 수 있습니다.
resource "local_file" "jpx_pem" {
  content  = tls_private_key.jpx_key.private_key_pem
  filename = "${path.module}/jpx-key.pem"
  file_permission = "0600" # 리눅스/맥 환경을 위해 권한을 600으로 제한
}

# =======================================================================
# 3. 배스천 호스트 EC2 전용 방화벽 (Security Group)
# =======================================================================
resource "aws_security_group" "jpx_bastion_sg" {
  name        = "jpx-bastion-security-group"
  description = "Allow SSH traffic to Bastion Host"
  vpc_id      = aws_vpc.jpx_vpc.id

  # [Inbound] 내 컴퓨터에서 EC2로 들어오는 SSH(22번 포트) 허용
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 실무에선 내 집 IP만 넣어야 하지만 우선 실습을 위해 전체 오픈!
  }

  # [Outbound] EC2가 외부 인터넷으로 패킷을 보내거나, 내부 프라이빗 DB(3306)로 찌를 수 있도록 전체 오픈
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jpx-bastion-sg" }
}

# =======================================================================
# 4. 실제 Public 서브넷에 입주할 징검다리 EC2 인스턴스 생성
# =======================================================================
resource "aws_instance" "jpx_bastion" {
  ami           = data.aws_ami.ubuntu.id # 위에서 동적으로 찾은 우분투 AMI ID 장착
  instance_type = "t3.micro"             # 프리티어 적용 가능한 기본 사양

  # 네트워크 세팅
  subnet_id                   = aws_subnet.public_subnet.id           # 외부 대문이 열려있는 퍼블릭 서브넷 방에 입주
  vpc_security_group_ids      = [aws_security_group.jpx_bastion_sg.id] # 22번 포트 방화벽 장착
  associate_public_ip_address = true                                  # 외부에서 접속해야 하므로 퍼블릭 IP 강제 활성화

  # 인증 키페어 장착
  key_name = aws_key_pair.jpx_keypair.key_name

  tags = {
    Name = "jpx-bastion-host"
  }
}