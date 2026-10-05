#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
: "${GITHUB_REPOSITORY:?Informe owner/repo}" "${GITHUB_BRANCH:?Informe main}"
[[ "$GITHUB_REPOSITORY" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]] || { echo 'Use owner/repo.' >&2; exit 1; }
[[ "$GITHUB_BRANCH" == main ]] || { echo 'O workflow entregue usa main; ajuste YAML e subject juntos se mudar a branch.' >&2; exit 1; }
app_name="github-${PREFIX}-cp5"
app_ids="$(az ad app list --display-name "$app_name" --query '[].appId' -o tsv)"
[[ "$(printf '%s\n' "$app_ids" | wc -l)" -le 1 ]] || { echo 'Mais de um aplicativo Entra com esse nome. Resolva a duplicidade.' >&2; exit 1; }
client_id="$app_ids"
if [[ -z "$client_id" ]]; then
  client_id="$(az ad app create --display-name "$app_name" --query appId -o tsv)"
fi
if ! az ad sp show --id "$client_id" --output none 2>/dev/null; then
  az ad sp create --id "$client_id" --output none
fi
sp_id="$(az ad sp show --id "$client_id" --query id -o tsv)"
scope="$(az group show -n "$RG" --query id -o tsv)"
az role assignment create --assignee-object-id "$sp_id" --assignee-principal-type ServicePrincipal \
  --role Contributor --scope "$scope" --output none
federation_file="$(mktemp)"
trap 'rm -f "$federation_file"' EXIT
export GITHUB_REPOSITORY GITHUB_BRANCH
python3 - "$federation_file" <<'PY'
import json,os,sys
with open(sys.argv[1],'w') as f:
 json.dump({'name':'github-main','issuer':'https://token.actions.githubusercontent.com',
  'subject':f"repo:{os.environ['GITHUB_REPOSITORY']}:ref:refs/heads/{os.environ['GITHUB_BRANCH']}",
  'audiences':['api://AzureADTokenExchange']},f)
PY
existing="$(az ad app federated-credential list --id "$client_id" --query "[?name=='github-main'].id | [0]" -o tsv)"
if [[ -n "$existing" ]]; then
  az ad app federated-credential update --id "$client_id" --federated-credential-id "$existing" --parameters "@$federation_file" --output none
else
  az ad app federated-credential create --id "$client_id" --parameters "@$federation_file" --output none
fi
tenant_id="$(az account show --query tenantId -o tsv)"
echo 'Cadastre estes valores em GitHub > Settings > Secrets and variables > Actions > Variables:'
printf 'AZURE_CLIENT_ID=%s\nAZURE_TENANT_ID=%s\nAZURE_SUBSCRIPTION_ID=%s\nAZURE_WEBAPP_NAME=%s\n' "$client_id" "$tenant_id" "$AZ_SUBSCRIPTION_ID" "$WEBAPP"
echo 'São identificadores. OIDC não precisa de client secret nem publish profile.'
