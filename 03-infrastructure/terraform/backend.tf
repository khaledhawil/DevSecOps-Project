terraform {
  backend "s3" {
    bucket         = "devsecops-terraform-state-2001"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-2001-lock"
    
    # Uncomment to use workspace-based state files
    # key = "environments/${terraform.workspace}/terraform.tfstate"
  }
}

# To create the S3 bucket and DynamoDB table for state management:
#
# aws s3api create-bucket \
#   --bucket devsecops-terraform-state \
#   --region us-east-1
#
# aws s3api put-bucket-versioning \
#   --bucket devsecops-terraform-state \
#   --versioning-configuration Status=Enabled
#
# aws s3api put-bucket-encryption \
#   --bucket devsecops-terraform-state \
#   --server-side-encryption-configuration \
#   '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
# aws dynamodb create-table \
#   --table-name terraform-state-lock \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1
