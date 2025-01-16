#!/bin/bash
# AWS Profile and Region
export AWS_EXECUTION_ENV="non-interactive"
export PROFILE="AWSAdministratorAccess-XXXXXXXXXX"
export REGION="eu-central-1"

# Function to create a table from a JSON file
create_table() {
  local JSON_FILE=$1

  echo "Creating table from file: $JSON_FILE"

  if [ ! -f "$JSON_FILE" ]; then
    echo "File $JSON_FILE not found!"
    exit 1
  fi

  # Extract the table name from the JSON file
  TABLE_NAME=$(jq -r '.Table.TableName' "$JSON_FILE")
  if [ -z "$TABLE_NAME" ]; then
    echo "Could not extract the table name from file $JSON_FILE"
    exit 1
  fi

  # Remove unnecessary configurations for recreation
  jq 'del(.Table.ProvisionedThroughput.LastIncreaseDateTime, 
          .Table.ProvisionedThroughput.LastDecreaseDateTime, 
          .Table.TableStatus, 
          .Table.CreationDateTime, 
          .Table.TableArn, 
          .Table.TableSizeBytes, 
          .Table.ItemCount, 
          .Table.TableId, 
          .Table.BillingModeSummary, 
          .Table.GlobalSecondaryIndexes[].IndexStatus, 
          .Table.GlobalSecondaryIndexes[].IndexSizeBytes, 
          .Table.GlobalSecondaryIndexes[].ItemCount, 
          .Table.GlobalSecondaryIndexes[].IndexArn, 
          .Table.StreamSpecification, 
          .Table.LatestStreamLabel, 
          .Table.LatestStreamArn)' "$JSON_FILE" > temp.json

  # Command to create the table in DynamoDB
  aws dynamodb create-table --cli-input-json file://temp.json \
    --profile "$PROFILE" --region "$REGION"

  if [ $? -ne 0 ]; then
    echo "Error creating table: $TABLE_NAME"
    rm -f temp.json
    exit 1
  fi

  echo "Table $TABLE_NAME successfully created!"
  rm -f temp.json
}

# Check if the file path was provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 path_to_file.json"
  exit 1
fi

# Create the table
create_table "$1" 