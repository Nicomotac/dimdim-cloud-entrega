#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ ! -f "$SCRIPT_DIR/config.local.sh" ]]; then
  echo 'Copie scripts/config.example.sh para scripts/config.local.sh e ajuste os valores.' >&2; exit 1
fi
source "$SCRIPT_DIR/config.local.sh"
: "${AZ_SUBSCRIPTION_ID:?Informe a assinatura}" "${PREFIX:?Informe o prefixo}" "${LOCATION:?Informe a região}"
[[ "$PREFIX" =~ ^[a-z][a-z0-9]{3,15}$ ]] || { echo 'PREFIX: 4 a 16 letras minúsculas/números, iniciando com letra.' >&2; exit 1; }
command -v az >/dev/null || { echo 'Instale Azure CLI ou use Azure Cloud Shell Bash.' >&2; exit 1; }
az account set --subscription "$AZ_SUBSCRIPTION_ID"
export RG="rg-${PREFIX}-cp5" PLAN="plan-${PREFIX}" WEBAPP="app-${PREFIX}-cp5"
export SQL_SERVER="sql-${PREFIX}-cp5" SQL_DATABASE="dimdim"
export WORKSPACE="log-${PREFIX}-cp5" INSIGHTS="appi-${PREFIX}-cp5"
export BASE_URL="https://${WEBAPP}.azurewebsites.net"
