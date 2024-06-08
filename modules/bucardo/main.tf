locals {
  heroku_pg_endpoint = jsondecode(data.aws_secretsmanager_secret_version.heroku_database_urls.secret_string)[var.service_name]
  heroku_host        = replace(split("/", split("@", local.heroku_pg_endpoint)[1])[0], ":5432", "")
  heroku_database    = reverse(split("/", local.heroku_pg_endpoint))[0]
  heroku_username    = split(":", replace(split("@", local.heroku_pg_endpoint)[0], "postgres://", ""))[0]
  heroku_password    = split(":", replace(split("@", local.heroku_pg_endpoint)[0], "postgres://", ""))[1]

  rds_credentials       = jsondecode(data.aws_secretsmanager_secret_version.rds_credentials.secret_string)
  rds_admin_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_admin_credentials.secret_string)
  rds_app_username      = "${var.service_name}_app"
  rds_reader_username   = "${var.service_name}_reader"
}


resource "aws_instance" "replicator" {
  ami                         = "ami-097c96b8f62c131c5" # Ubuntu 22.04
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  # Created separately with aws ec2 create-key-pair (unsupported in Terraform)
  key_name                    = "bucardo-replicator-key-pair"

  root_block_device {
    volume_size = "30"
  }

  subnet_id = aws_subnet.public_subnet.id

  vpc_security_group_ids = [aws_security_group.security_group.id]

  depends_on = [aws_internet_gateway.vpc_gateway]

  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/../modules/bucardo/scripts/setup.sh.tftpl", {
    service_name            = var.service_name,
    rds_host                = var.rds_instance.host,
    rds_database            = "${var.service_name}_db",
    rds_admin_username      = local.rds_admin_credentials["username"],
    rds_admin_password      = local.rds_admin_credentials["password"],
    rds_bucardo_username    = "bucardo_replicator",
    rds_bucardo_password    = local.rds_credentials["bucardo_replicator"],
    rds_app_username        = local.rds_app_username,
    rds_reader_username     = local.rds_reader_username,
    rds_app_password        = local.rds_credentials[local.rds_app_username],
    rds_reader_password     = local.rds_credentials[local.rds_reader_username],
    heroku_host             = local.heroku_host,
    heroku_database         = local.heroku_database,
    heroku_username         = local.heroku_username,
    heroku_password         = local.heroku_password,
    heroku_pg_major_version = var.heroku_pg_major_version,
  })

  tags = {
    Name = "Bucardo one-off Postgres replicator for ${var.service_name}"
  }
}

resource "aws_network_interface_attachment" "network_interface_attachment" {
  instance_id          = aws_instance.replicator.id
  network_interface_id = aws_network_interface.primary_network_interface.id
  device_index         = 1
}

resource "aws_network_interface" "primary_network_interface" {
  subnet_id = aws_subnet.public_subnet.id

  tags = {
    Name = "bucardo_replicator_primary_network_interface"
  }
}
