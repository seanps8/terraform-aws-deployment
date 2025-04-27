#!/bin/bash

set -e

# Load environment variables
export TF_VAR_db_user="admin"
export TF_VAR_db_password="1234567890"

# Read from aws.tfvars
AWS_REGION=$(grep aws_region aws.tfvars | cut -d '"' -f2)
AWS_PROFILE=$(grep aws_profile aws.tfvars | cut -d '"' -f2)
STATE_BUCKET=$(grep state_bucket aws.tfvars | cut -d '"' -f2)
STATE_KEY=$(grep state_key aws.tfvars | cut -d '"' -f2)

# Create the Terraform state bucket if it doesn't exist
echo "Checking if S3 bucket $STATE_BUCKET exists..."

if aws s3api head-bucket --bucket "$STATE_BUCKET" --profile "$AWS_PROFILE" 2>/dev/null; then
    echo "Bucket $STATE_BUCKET already exists."
else
    echo "🔹 Creating bucket $STATE_BUCKET..."
    aws s3api create-bucket \
        --bucket "$STATE_BUCKET" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE"
    echo "Bucket created."
fi

# Initialize backend
export AWS_PROFILE="$AWS_PROFILE"
export AWS_REGION="$AWS_REGION"
echo "Initializing Terraform backend..."
terraform init -reconfigure \
    -backend-config="bucket=${STATE_BUCKET}" \
    -backend-config="key=${STATE_KEY}" \
    -backend-config="region=${AWS_REGION}"

# Build app
cd app/
./build.sh
cd ..

# Terraform apply
echo "Applying Terraform..."
terraform apply -auto-approve -var-file="aws.tfvars"

# Get S3 Upload Bucket
S3_UPLOAD_BUCKET=$(terraform output -raw s3_upload_bucket)
echo "Uploading data to: $S3_UPLOAD_BUCKET"

# Download and upload file
curl -L -o flightlist.csv.gz "https://zenodo.org/records/5377831/files/flightlist_20190201_20190228.csv.gz?download=1"
aws s3 cp flightlist.csv.gz s3://$S3_UPLOAD_BUCKET/ --profile "$AWS_PROFILE"

API_URL=$(terraform output -raw api_invoke_url)
echo "Deployed Successfully! Because the file is so large, it can take a couple minutes for everything to process. Check this api url in about 2-3 minutes --> $API_URL"
rm -rf flightlist.csv.gz