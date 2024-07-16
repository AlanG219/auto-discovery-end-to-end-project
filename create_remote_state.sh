# Run each of the below commands to provision s3 and dynamodb table via aws cli
# Can be run on terminal or by pasting into file and running file with sh command


# Set variables
BUCKET_NAME="pet_auto_remote_tf"
DYNAMODB_TABLE_NAME="pet_auto_dynamodb"
REGION="eu-west-1"

# Create S3 bucket
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION --create-bucket-configuration LocationConstraint=$REGION

# Tag the S3 bucket
aws s3api put-bucket-tagging --bucket $BUCKET_NAME --tagging 'TagSet=[{Key=Name,Value=pet_auto_remote_tf}]'

# Create DynamoDB table
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=10 \
    --region $REGION