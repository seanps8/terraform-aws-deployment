output "api_invoke_url" {
  value = module.api-gw.api_invoke_url
}

output "s3_upload_bucket" {
  value = module.storage.data_bucket_name
}