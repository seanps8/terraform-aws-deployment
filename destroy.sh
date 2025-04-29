#!/bin/bash
set -e

# Read from aws.tfvars
AWS_REGION=$(grep aws_region aws.tfvars | cut -d '"' -f2)
AWS_PROFILE=$(grep aws_profile aws.tfvars | cut -d '"' -f2)
STATE_BUCKET=$(grep state_bucket aws.tfvars | cut -d '"' -f2)
STATE_KEY=$(grep state_key aws.tfvars | cut -d '"' -f2)

export AWS_PROFILE="$AWS_PROFILE"
export AWS_REGION="$AWS_REGION"
export TF_VAR_db_user="admin"
export TF_VAR_db_password="1234567890"

echo "Starting Terraform destroy..."

# Run terraform destroy
terraform destroy -auto-approve -var-file="aws.tfvars"

# delete state bucket
echo "Deleting Terraform state bucket: $STATE_BUCKET"
aws s3 rb s3://$STATE_BUCKET --force

echo "Destroy complete!"