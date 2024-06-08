output "instance_ip" {
  description = "The public IP for SSH access"
  value       = aws_instance.replicator.public_ip
}

resource "local_file" "bucardo_start_instructions_script" {
  filename = "${path.cwd}/.bucardo_scripts/start_instructions.${var.service_name}.sh"
  content  = templatefile("${path.module}/../modules/bucardo/scripts/start_instructions.sh.tftpl", {
    service_name        = var.service_name,
    environment         = var.environment,
    rds_host            = var.rds_instance.host,
    rds_database        = "${var.service_name}_db",
    rds_app_username    = local.rds_app_username,
    rds_app_password    = local.rds_credentials[local.rds_app_username],
    replicator_ip       = aws_instance.replicator.public_ip,
  })
}

resource "local_file" "bucardo_cleanup_instructions_script" {
  filename = "${path.cwd}/.bucardo_scripts/cleanup_instructions.${var.service_name}.sh"
  content  = templatefile("${path.module}/../modules/bucardo/scripts/cleanup_instructions.sh.tftpl", {
    service_name = var.service_name,
  })
}

resource "local_file" "bucardo_reset_instructions_script" {
  filename = "${path.cwd}/.bucardo_scripts/reset_instructions.${var.service_name}.sh"
  content  = templatefile("${path.module}/../modules/bucardo/scripts/reset_instructions.sh.tftpl", {
    service_name = var.service_name,
  })
}
