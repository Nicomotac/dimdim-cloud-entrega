#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
echo "Apaga permanentemente o grupo $RG e seu banco. Use SOMENTE após a correção/backup."
read -rp 'Digite o nome exato do grupo para excluir: ' confirmed
[[ "$confirmed" == "$RG" ]] || { echo 'Cancelado.'; exit 1; }
az group delete --name "$RG" --yes --no-wait
echo 'Exclusão solicitada. O registro de aplicativo Entra/OIDC não pertence ao grupo; remova-o separadamente se não for mais necessário.'
