#!/bin/bash
BASE_DIR=$(cd "$(dirname "$0")" || exit; pwd -P)
DATA_DIR="${BASE_DIR}/datadir"

if [ ! -d "${DATA_DIR}" ]; then
    echo "Initializing geth..."
    geth --datadir "${DATA_DIR}" --nodiscover init "${BASE_DIR}/genesis.json"
fi

echo "Starting geth console..."
echo "" > "/tmp/geth-blank-password"

geth --datadir "${DATA_DIR}" account import "./key.priv" --password "/tmp/geth-blank-password"
geth --datadir "${DATA_DIR}" account import "./key2.priv" --password "/tmp/geth-blank-password"

geth \
  --miner.gastarget 7500000 \
  --networkid 1337 \
  --miner.gasprice "10" \
  --nodiscover \
  --maxpeers 0 \
  --etherbase "6de4b3b9c28e9c3e84c2b2d3a875c947a84de68d" \
  --keystore "${DATA_DIR}/keystore" \
  --datadir "${DATA_DIR}" \
  --password "/tmp/geth-blank-password" \
  --unlock "0,1" \
  --syncmode 'full' \
  --rpc --rpcapi personal,web3,eth,net --rpcaddr 0.0.0.0 --rpcvhosts=* --rpcport=8545 \
  --ws --wsaddr 0.0.0.0 --wsorigins='*' \
  --mine \
  --allow-insecure-unlock
