#!/bin/bash

# Define service ID and API key
SERVICE_ID="you-render-service-id"
API_KEY="you-render-api-key"

# Make the API call and format the response
curl --silent --request GET \
  --url "https://api.render.com/v1/services/${SERVICE_ID}/env-vars?limit=20" \
  --header "accept: application/json" \
  --header "authorization: Bearer ${API_KEY}" \
  | jq -r '.[] | (.envVar.key + "=\"" + .envVar.value + "\"")'