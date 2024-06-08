variable "service_name" {
  description = "The service name (lowercase, snake case). The Bucardo instance will be set up with these details"
  type        = string
}

variable "heroku_pg_major_version" {
  description = "The major version of Postgres on the Heroku instance for this service."
  type        = string
}

variable "rds_instance" {
  description = "The Terraform RDS resource object for this service."
  type        = object({
    host                  = string,
    admin_credentials_arn = string,
    security_group_id     = string,
  })
}

variable "rds_vpc" {
  description = "The Terraform VPC resource object where the RDS instance is located (typically the stateful VPC)."
  type        = object({
    id                     = string,
    cidr_block             = string,
    default_route_table_id = string,
  })
}

variable "environment" {
  type = string
}

variable "aws_public_subnet_cidr_block" {
  description = "Public subnet CIDR Block for Bucardo Replication"
  type = string
}

variable "aws_public_vpc_cidr_block" {
  description = "Public VPC CIDR Block for Bucardo Replication"
  type = string
}
