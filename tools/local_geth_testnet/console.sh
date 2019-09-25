#!/bin/bash
BASE_DIR=$(cd "$(dirname "$0")" || exit; pwd -P)
DATA_DIR="${BASE_DIR}/datadir"

if [ ! -d "${DATA_DIR}" ]; then
    echo "Initializing geth..."
    geth --datadir "${DATA_DIR}" --nodiscover init "${BASE_DIR}/genesis.json"
fi

echo "Starting geth console..."

geth \
  --identity "local-geth" \
  --networkid 1337 \
  --datadir "${DATA_DIR}" --nodiscover \
  --allow-insecure-unlock \
  --rpc --rpcvhosts "*" --rpccorsdomain "*" \
  --rpcapi "db,eth,net,web3" \
  --nat "any" \
  console
