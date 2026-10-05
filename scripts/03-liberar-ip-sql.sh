#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
read -rp 'IPv4 público exibido pelo Query Editor ou do computador que vai consultar o banco: ' client_ip
python3 - "$client_ip" <<'PY'
import ipaddress,sys
if ipaddress.ip_address(sys.argv[1]).version != 4: raise SystemExit('Informe IPv4.')
PY
az sql server firewall-rule create -g "$RG" -s "$SQL_SERVER" -n demonstracao \
  --start-ip-address "$client_ip" --end-ip-address "$client_ip" --output none
echo 'IP liberado. Use o Query Editor ou sqlcmd conectado ao banco dimdim.'
