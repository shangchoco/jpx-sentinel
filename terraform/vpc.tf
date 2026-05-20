# vpc.tf

# 1. VPC 생성
resource "aws_vpc" "jpx_vpc" {
  cidr_block           = "10.0.0.0/16" # 10.0.x.x 대역을 우리가 통째로 점유합니다
  enable_dns_hostnames = true          # 도메인 이름 지원 활성화
  enable_dns_support   = true

  tags = {
    Name = "jpx-project-vpc"
  }
}

# 2. 외부 인터넷과 통하는 Public 서브넷 (스프링 부트 웹서버용)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.jpx_vpc.id # 위에서 만든 VPC ID를 자동으로 가져옵니다
  cidr_block              = "10.0.1.0/24"      # 10.0.1.x 대역 사용
  availability_zone       = "ap-northeast-1a"  # 도쿄 1a 데이터센터에 격리
  map_public_ip_on_launch = true               # 이 구역에 생기는 서버는 외부 IP를 가집니다

  tags = {
    Name = "jpx-public-subnet"
  }
}

# 3. 외부와 차단된 안전한 Private 서브넷 (MySQL DB용)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.jpx_vpc.id
  cidr_block        = "10.0.2.0/24"      # 10.0.2.x 대역 사용
  availability_zone = "ap-northeast-1a"  # 똑같이 도쿄 1a 데이터센터에 위치

  tags = {
    Name = "jpx-private-subnet"
  }
}

# 4. 외부 인터넷 세상과 통하는 '대문' (인터넷 게이트웨이) 생성
resource "aws_internet_gateway" "jpx_igw" {
  vpc_id = aws_vpc.jpx_vpc.id

  tags = {
    Name = "jpx-internet-gateway"
  }
}

# 5. Public 서브넷을 위한 '길 안내 표지판' (라우팅 테이블)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.jpx_vpc.id

  # "외부 인터넷(0.0.0.0/0)으로 나가는 트래픽은 방금 만든 대문(igw)을 거쳐라!"라는 규칙
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jpx_igw.id
  }

  tags = {
    Name = "jpx-public-route-table"
  }
}

# 6. 이 길 안내 표지판을 진짜 'Public 서브넷'에 장착하기
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}