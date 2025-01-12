#!/usr/bin/env bash
#
# Bash script to insert items into a DynamoDB table chosen by the user,
# using AWS CLI, fzf, and jq.
#
# Steps:
#  1. List AWS CLI profiles
#  2. User picks a profile via fzf
#  3. List DynamoDB tables from that profile
#  4. User picks a table
#  5. User picks a .json file that contains an array of items
#  6. Read each array element (must be in DynamoDB AttributeValue format)
#  7. Insert each item with aws dynamodb put-item

# Check for 'aws'
if ! command -v aws &>/dev/null; then
  echo "ERROR: AWS CLI is not installed or not in PATH." >&2
  exit 1
fi

# Check for 'fzf'
if ! command -v fzf &>/dev/null; then
  echo "ERROR: fzf is not installed or not in PATH." >&2
  exit 1
fi

# Check for 'jq'
if ! command -v jq &>/dev/null; then
  echo "ERROR: jq is not installed or not in PATH." >&2
  exit 1
fi

echo "*************************************************************** Retrieving AWS CLI profiles... ***************************************************************"
PROFILES=$(aws configure list-profiles 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$PROFILES" ]; then
  echo "ERROR: Could not list AWS profiles. Check your AWS CLI installation and credentials."
  exit 1
fi

echo "*************************************************************** Select the AWS profile to use (up/down to navigate, Enter to confirm)... ***************************************************************"
SELECTED_PROFILE=$(echo "$PROFILES" | fzf --prompt "Profile> ")
if [ -z "$SELECTED_PROFILE" ]; then
  echo "No profile selected. Exiting."
  exit 1
fi

echo "*************************************************************** Selected profile: $SELECTED_PROFILE ***************************************************************"
echo "*************************************************************** Listing DynamoDB tables for profile '$SELECTED_PROFILE'...  ***************************************************************"

TABLES_JSON=$(aws dynamodb list-tables --profile "$SELECTED_PROFILE" --output json 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "ERROR: Could not list DynamoDB tables. Check your profile credentials/permissions."
  exit 1
fi

TABLES_LIST=$(echo "$TABLES_JSON" | jq -r '.TableNames[]?' )
if [ -z "$TABLES_LIST" ]; then
  echo "No DynamoDB tables found for profile '$SELECTED_PROFILE'. Exiting."
  exit 0
fi

echo "==> Select the DynamoDB table (up/down to navigate, Enter to confirm)..."
SELECTED_TABLE=$(echo "$TABLES_LIST" | fzf --prompt "Table> ")
if [ -z "$SELECTED_TABLE" ]; then
  echo "No table selected. Exiting."
  exit 1
fi

echo "==> Selected table: $SELECTED_TABLE"

echo "==> Select a .json file in the current directory (containing an array of items)..."
JSON_FILE=$(ls *.json 2>/dev/null | fzf --prompt "JSON file> ")
if [ -z "$JSON_FILE" ]; then
  echo "No JSON file selected. Exiting."
  exit 1
fi

echo "*************************************************************** Selected file: $JSON_FILE ***************************************************************"

echo "*************************************************************** Reading items from '$JSON_FILE'... ***************************************************************"
ITEMS=$(jq -c '.[]' "$JSON_FILE" 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "ERROR: Could not parse the JSON file with jq. Ensure the file is valid JSON."
  exit 1
fi

if [ -z "$ITEMS" ]; then
  echo "No items found (array is empty) in '$JSON_FILE'. Exiting."
  exit 1
fi

echo "*************************************************************** Inserting items into table: $SELECTED_TABLE ***************************************************************"
COUNT=0

# Loop through each line (each line is one JSON object in AttributeValue format)
while IFS= read -r ITEM; do
  COUNT=$((COUNT + 1))
  echo "[Item #$COUNT] Putting item: $ITEM"
  
  aws dynamodb put-item \
    --profile "$SELECTED_PROFILE" \
    --table-name "$SELECTED_TABLE" \
    --item "$ITEM" \
    --return-consumed-capacity TOTAL \
    >/dev/null
  
  if [ $? -eq 0 ]; then
    echo "Successfully inserted."
  else
    echo "ERROR inserting this item."
  fi
done <<< "$ITEMS"

echo "*************************************************************** Done. Total items processed: $COUNT ***************************************************************"