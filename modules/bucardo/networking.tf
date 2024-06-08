# Networking requirements:
# 1. The EC2 instance running Bucardo (the "replicator") needs to be accessible from the Internet (for SSH).
# 2. The replicator needs to be able to access the Internet (to access the Heroku database)
# 3. The replicator needs to be peered with the stateful VPC (to access the RDS database)

resource "aws_internet_gateway" "vpc_gateway" {
  vpc_id = aws_vpc.public_vpc.id
}

resource "aws_vpc_peering_connection" "stateful_vpc_peering" {
  auto_accept = true
  peer_vpc_id = var.rds_vpc.id
  vpc_id      = aws_vpc.public_vpc.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = {
    Name = "VPC peering Bucardo VPC (${var.service_name}) - Stateful VPC"
  }
}

resource "aws_route" "peer_route" {
  route_table_id            = aws_route_table.route_table.id
  destination_cidr_block    = var.rds_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.stateful_vpc_peering.id
}

resource "aws_route" "reverse_peer_route" {
  route_table_id            = var.rds_vpc.default_route_table_id
  destination_cidr_block    = aws_subnet.public_subnet.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.stateful_vpc_peering.id
}

resource "aws_route" "internet_route" {
  route_table_id         = aws_route_table.route_table.id
  gateway_id             = aws_internet_gateway.vpc_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.public_vpc.id
}

resource "aws_route_table_association" "route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.public_vpc.id
  cidr_block = var.aws_public_subnet_cidr_block

  tags = {
    Name = "bucardo_replicator_${var.service_name}_public_subnet"
  }
}

resource "aws_vpc" "public_vpc" {
  cidr_block           = var.aws_public_vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = "bucardo_replicator_${var.service_name}_public_vpc"
  }
}

resource "aws_security_group" "security_group" {
  name        = "bucardo_replicator_security_group"
  description = "Security group to allow inbound SSH connections"
  vpc_id      = aws_vpc.public_vpc.id

  tags = {
    Name = "bucardo_replicator_${var.service_name}_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "security_group_ingress_ssh" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# Allow connections to the RDS instance from Bucardo
resource "aws_vpc_security_group_ingress_rule" "rds_bucardo_security_group_ingress" {
  security_group_id = var.rds_instance.security_group_id
  description       = "Allow Postgres connections from Bucardo replicator for ${var.service_name}"
  tags = {
    Name = "Bucardo (${var.service_name})"
  }
  cidr_ipv4         = var.aws_public_subnet_cidr_block
  ip_protocol       = "tcp"

  from_port = 5432
  to_port   = 5432
}

resource "aws_vpc_security_group_egress_rule" "security_group_egress_all_ipv4" {
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" #` All ports
}

resource "aws_default_network_acl" "acl" {
  default_network_acl_id = aws_vpc.public_vpc.default_network_acl_id

  subnet_ids = [
    aws_subnet.public_subnet.id
  ]

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 65535
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  tags = {
    Name = "bucardo_${var.service_name}_network_acl"
  }
}
