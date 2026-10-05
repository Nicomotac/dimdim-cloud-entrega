#!/usr/bin/env bash
set -euo pipefail
set +x
source "$(dirname "$0")/common.sh"
command -v python3 >/dev/null
echo "Criando recursos de laboratório em $RG / $LOCATION. App Service, SQL e logs podem gerar cobrança."
echo 'As próximas entradas ficam ocultas; não grave a tela com configurações/credenciais abertas.'
read -rs -p 'Administrador SQL (nome exclusivo, não use admin/sa): ' SQL_ADMIN; echo
read -rs -p 'Senha SQL (8 a 128 caracteres, conforme politica Azure): ' SQL_PASSWORD; echo
read -rs -p 'Usuário para entrar no DimDim: ' APP_USERNAME; echo
read -rs -p 'Senha de acesso ao DimDim: ' APP_PASSWORD; echo
[[ -n "$SQL_ADMIN" && -n "$APP_USERNAME" && -n "$SQL_PASSWORD" && -n "$APP_PASSWORD" ]] || { echo 'Preencha os quatro campos.' >&2; exit 1; }
export SQL_ADMIN SQL_PASSWORD APP_USERNAME APP_PASSWORD
python3 - <<'VALIDAR_SQL'
import os, re
password = os.environ['SQL_PASSWORD']
username = os.environ['SQL_ADMIN']
categories = sum(bool(re.search(pattern, password)) for pattern in (r'[A-Z]', r'[a-z]', r'[0-9]', r'[^a-zA-Z0-9]'))
if not 8 <= len(password) <= 128 or categories < 3 or username.lower() in password.lower():
    raise SystemExit('Senha SQL recusada: use 8 a 128 caracteres, tres categorias (maiusculas, minusculas, numeros ou simbolos) e nao inclua o nome do administrador. Essa regra e do Azure SQL.')
VALIDAR_SQL
settings_file="$(mktemp)"
chmod 600 "$settings_file"
trap 'rm -f "$settings_file"; unset SQL_PASSWORD APP_PASSWORD DB_PASSWORD APPLICATIONINSIGHTS_CONNECTION_STRING' EXIT
for provider in Microsoft.Web Microsoft.Sql Microsoft.Insights Microsoft.OperationalInsights; do
  az provider register --namespace "$provider" --wait --output none
done
az extension add --name application-insights --upgrade --only-show-errors --output none
az group create --name "$RG" --location "$LOCATION" --tags project=dimdim checkpoint=cp5 --output none
az monitor log-analytics workspace create --resource-group "$RG" --workspace-name "$WORKSPACE" \
  --location "$LOCATION" --retention-time 30 --output none
workspace_id="$(az monitor log-analytics workspace show -g "$RG" -n "$WORKSPACE" --query id -o tsv)"
az monitor app-insights component create --app "$INSIGHTS" --location "$LOCATION" -g "$RG" \
  --application-type web --workspace "$workspace_id" --output none
az sql server create -g "$RG" -n "$SQL_SERVER" -l "$LOCATION" \
  --admin-user "$SQL_ADMIN" --admin-password "$SQL_PASSWORD" --minimal-tls-version 1.2 --output none
az sql db create -g "$RG" -s "$SQL_SERVER" -n "$SQL_DATABASE" \
  --service-objective "${SQL_SERVICE_OBJECTIVE:-Basic}" --backup-storage-redundancy Local --output none
az appservice plan create -g "$RG" -n "$PLAN" -l "$LOCATION" --is-linux --sku "${APP_SERVICE_SKU:-B1}" --output none
az webapp create -g "$RG" -p "$PLAN" -n "$WEBAPP" --runtime 'JAVA:17-java17' --output none
az webapp update -g "$RG" -n "$WEBAPP" --https-only true --output none
az webapp config set -g "$RG" -n "$WEBAPP" --always-on true --min-tls-version 1.2 \
  --ftps-state Disabled --startup-file 'java -jar /home/site/wwwroot/app.jar' --output none
# Não libera 0.0.0.0 (todos os serviços Azure). Libera apenas possíveis IPs de saída do app.
ips="$(az webapp show -g "$RG" -n "$WEBAPP" --query possibleOutboundIpAddresses -o tsv)"
[[ -n "$ips" ]] || { echo 'Não foi possível obter os IPs de saída do app.' >&2; exit 1; }
IFS=',' read -ra outbound_ips <<< "$ips"
i=0
for ip in "${outbound_ips[@]}"; do
  i=$((i+1))
  az sql server firewall-rule create -g "$RG" -s "$SQL_SERVER" -n "app-out-$i" \
    --start-ip-address "$ip" --end-ip-address "$ip" --output none
done
export APPLICATIONINSIGHTS_CONNECTION_STRING
APPLICATIONINSIGHTS_CONNECTION_STRING="$(az monitor app-insights component show --app "$INSIGHTS" -g "$RG" --query connectionString -o tsv)"
[[ -n "$APPLICATIONINSIGHTS_CONNECTION_STRING" ]] || { echo 'Application Insights sem connection string.' >&2; exit 1; }
python3 - "$settings_file" <<'PY'
import json, os, sys
e=os.environ
settings={
 'DB_URL':f"jdbc:sqlserver://{e['SQL_SERVER']}.database.windows.net:1433;databaseName={e['SQL_DATABASE']};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;",
 'DB_USERNAME':e['SQL_ADMIN'], 'DB_PASSWORD':e['SQL_PASSWORD'],
 'APP_USERNAME':e['APP_USERNAME'], 'APP_PASSWORD':e['APP_PASSWORD'],
 'APPLICATIONINSIGHTS_CONNECTION_STRING':e['APPLICATIONINSIGHTS_CONNECTION_STRING'],
 'ApplicationInsightsAgent_EXTENSION_VERSION':'~3',
 'APPLICATIONINSIGHTS_CONFIGURATION_CONTENT':json.dumps({'role':{'name':'dimdim-cloud'},'sampling':{'percentage':100}}),
 'SCM_DO_BUILD_DURING_DEPLOYMENT':'false'
}
with open(sys.argv[1],'w') as f: json.dump(settings,f)
PY
az webapp config appsettings set -g "$RG" -n "$WEBAPP" --settings "@$settings_file" --output none
db_id="$(az sql db show -g "$RG" -s "$SQL_SERVER" -n "$SQL_DATABASE" --query id -o tsv)"
az monitor diagnostic-settings create --name sql-monitor --resource "$db_id" --workspace "$workspace_id" \
  --logs '[{"categoryGroup":"allLogs","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]' --output none
echo "Recursos configurados. URL de destino: $BASE_URL"
echo 'Próximo: bash scripts/02-configurar-oidc.sh. O aplicativo ainda precisa do deploy do GitHub Actions.'
