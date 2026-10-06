#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Não exibir credenciais mesmo se o chamador tiver habilitado xtrace.
set +x
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
if [[ -f "$PROJECT_DIR/.env" ]]; then
  # .env é configuração Bash local e confiável; exporta para processos filhos.
  set -a
  source "$PROJECT_DIR/.env"
  set +a
elif [[ -f "$SCRIPT_DIR/config.local.sh" ]]; then
  # Compatibilidade com instalações anteriores; .env tem prioridade.
  source "$SCRIPT_DIR/config.local.sh"
else
  echo 'Copie .env.example para .env na raiz e preencha os valores localmente.' >&2
  exit 1
fi
: "${AZ_SUBSCRIPTION_ID:?Informe a assinatura}" "${PREFIX:?Informe o prefixo}" "${LOCATION:?Informe a região}"
[[ "$PREFIX" =~ ^[a-z][a-z0-9]{3,15}$ ]] || { echo 'PREFIX: 4 a 16 letras minúsculas/números, iniciando com letra.' >&2; exit 1; }
command -v az >/dev/null || { echo 'Instale Azure CLI ou use Azure Cloud Shell Bash.' >&2; exit 1; }
az account set --subscription "$AZ_SUBSCRIPTION_ID"
export RG="rg-${PREFIX}-cp5" PLAN="plan-${PREFIX}" WEBAPP="app-${PREFIX}-cp5"
export SQL_SERVER="sql-${PREFIX}-cp5" SQL_DATABASE="dimdim"
export WORKSPACE="log-${PREFIX}-cp5" INSIGHTS="appi-${PREFIX}-cp5"
export BASE_URL="https://${WEBAPP}.azurewebsites.net"
