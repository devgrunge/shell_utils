#!/bin/bash
# Perfil e região AWS
export AWS_EXECUTION_ENV="non-interactive"
export PROFILE="AWSAdministratorAccess-xxxxxxxxx"
export REGION="eu-central-1"
MAX_JOBS=8  # Número máximo de trabalhos simultâneos
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
export LOG_FILE="logs_$TIMESTAMP.json"

# Função para descrever uma tabela e salvar a configuração
describe_table() {
  local TABLE_NAME=$1

  echo "Describing table: $TABLE_NAME"

  # Comando para descrever a tabela e salvar em um arquivo JSON
  aws dynamodb describe-table --table-name "$TABLE_NAME" \
    --output json --profile "$PROFILE" --region "$REGION" > "${TABLE_NAME}-config.json"

  if [ $? -ne 0 ]; then
    echo "Erro ao descrever a tabela: $TABLE_NAME"
    exit 1
  fi

  echo "Configuração da tabela $TABLE_NAME salva em ${TABLE_NAME}-config.json"
}

# Exportar a função para uso em subshells
export -f describe_table

# Listar todas as tabelas e processá-las em paralelo
aws dynamodb list-tables --output json --profile "$PROFILE" --region "$REGION" | jq -r '.TableNames[]' | \
xargs -n 1 -P "$MAX_JOBS" -I {} bash -c 'describe_table "$@"' _ {}