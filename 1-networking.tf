////////////////////////
// VPC
////////////////////////
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-VPC"
  }
}

////////////////////////
// SUBNETS
////////////////////////
resource "aws_subnet" "public-1-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name    = "${var.environment}-public-1-a"
    Network = "public"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "private-2-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name    = "${var.environment}-private-2-a"
    Network = "private"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "private-3-a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name    = "${var.environment}-private-3-a"
    Network = "public"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "public-1-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name    = "${var.environment}-public-1-b"
    Network = "public"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "private-2-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name    = "${var.environment}-private-2-b"
    Network = "private"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_subnet" "private-3-b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${var.region}b"

  tags = {
    Name    = "${var.environment}-private-3-b"
    Network = "public"
  }
  depends_on = [aws_internet_gateway.main]
}

////////////////////////
// ROUTES
////////////////////////
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "public route table"
    Network = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "10.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name    = "private route table"
    Network = "private"
  }
}

resource "aws_route_table_association" "public-1-a" {
  subnet_id      = aws_subnet.public-1-a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-1-b" {
  subnet_id      = aws_subnet.public-1-b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-2-a" {
  subnet_id      = aws_subnet.private-2-a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-3-a" {
  subnet_id      = aws_subnet.private-3-a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-2-b" {
  subnet_id      = aws_subnet.private-2-b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-3-b" {
  subnet_id      = aws_subnet.private-3-b.id
  route_table_id = aws_route_table.private.id
}

////////////////////////
// IGW
////////////////////////
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

////////////////////////
// EIP
////////////////////////
resource "aws_eip" "nat" {
  vpc        = true
  depends_on = [aws_internet_gateway.main]
}

////////////////////////
// NAT GATEWAY
////////////////////////
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-1-b.id

  tags = {
    Name = "${var.environment}-nat"
  }
  depends_on = [aws_internet_gateway.main]
}