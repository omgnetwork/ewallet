#!/bin/bash
DATA_DIR=$(pwd -P)/datadir

if [ ! -d "${DATA_DIR}" ]; then
    echo "Initializing geth..."
    geth --datadir "${DATA_DIR}" --nodiscover init genesis.json
fi

echo "Starting geth console..."
geth --identity "local-geth" --rpc  --rpccorsdomain "*" --datadir "${DATA_DIR}" --nodiscover --rpcapi "db,eth,net,web3" --nat "any" console