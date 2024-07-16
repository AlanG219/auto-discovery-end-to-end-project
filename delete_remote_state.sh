# Run each of the below commands to destroy s3 and dynamodb table via aws cli
# Can be run on terminal or by pasting into file and running file with sh command


# Set variables
BUCKET_NAME="pet_auto_remote_tf"
DYNAMODB_TABLE_NAME="pet_auto_dynamodb"
REGION="eu-west-1"

# Delete all objects from the S3 bucket
aws s3 rm s3://$BUCKET_NAME --recursive

# Delete the S3 bucket
aws s3api delete-bucket --bucket $BUCKET_NAME --region $REGION

# Delete DynamoDB table
aws dynamodb delete-table --table-name $DYNAMODB_TABLE_NAME --region $REGION
