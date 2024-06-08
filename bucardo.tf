module "bucardo_replication" {
  source = "../modules/bucardo"

  rds_vpc                 = module.stateful-vpc # Reference to the VPC module used by our RDS databases
  service_name            = "some_service"
  heroku_pg_major_version = "13"
  rds_instance            = module.some_service_rds # Reference to the RDS module for this service
  environment             = "staging"
}
