module "vpc" {
  source = "./modules/vpc"
}

module "storage" {
  source      = "./modules/storage"
  subnet_ids  = module.vpc.private_subnet_ids
  db_password = var.db_password
  db_user     = var.db_user
}

module "lambda" {
  source          = "./modules/lambda"
  rds_host        = module.storage.rds_host
  db_user         = var.db_user
  db_name         = module.storage.db_name
  db_password     = var.db_password
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  data_bucket_id  = module.storage.data_bucket_id
  data_bucket_arn = module.storage.data_bucket_arn
}

module "api-gw" {
  source = "./modules/api-gw"
  invoke_arn = module.lambda.invoke_arn
  function_name = module.lambda.function_name
}