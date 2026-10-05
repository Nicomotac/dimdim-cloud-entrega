#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
db_id="$(az sql db show -g "$RG" -s "$SQL_SERVER" -n "$SQL_DATABASE" --query id -o tsv)"
echo 'Métricas Azure SQL (última hora). Gere operações no aplicativo antes de consultar.'
az monitor metrics list --resource "$db_id" --metric cpu_percent dtu_consumption_percent sessions_percent \
  --interval PT1M --aggregation Average --offset 1h --output json
echo 'Requisições coletadas no Application Insights (última hora):'
az monitor app-insights query -g "$RG" --app "$INSIGHTS" --analytics-query \
  'requests | where timestamp > ago(1h) | summarize chamadas=count(), falhas=countif(success == false), duracao_media_ms=avg(duration) by name | order by chamadas desc' -o table
echo 'Dependências SQL coletadas no Application Insights:'
az monitor app-insights query -g "$RG" --app "$INSIGHTS" --analytics-query \
  'dependencies | where timestamp > ago(1h) | where type has "SQL" | project timestamp, name, target, type, duration, success, operation_Id | order by timestamp desc | take 30' -o table
