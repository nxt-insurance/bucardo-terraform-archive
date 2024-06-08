module "bucardo_replication" {
  source = "../modules/bucardo"

  rds_vpc                 = module.stateful-vpc
  service_name            = "some_service"
  heroku_pg_major_version = "13"
  rds_instance            = module.some_service_rds
  environment             = "staging"
}
