#!/bin/sh

print_usage() {
    printf "Usage: %s [CONFIG..] [OPTS]\\n" "$0"
    printf "\\n"
    printf "Generates a Docker-Compose configuration overrides for various\\n"
    printf "purposes. This script will output to STDOUT, it is expected that\\n"
    printf "a user will pipe its output into a file. For example:\\n"
    printf "\\n"
    printf "     %s > docker-compose.override.yml\\n" "$0"
    printf "\\n"
    printf "OPTS:\\n"
    printf "\\n"
    printf "     -h         Prints this help.\\n"
    printf "     -d         Generates a development override.\\n"
    printf "\\n"
    printf "CONFIG:\\n"
    printf "\\n"
    printf "     -i image   Specify an alternative eWallet image name.\\n"
    printf "     -n network Specify an external network.\\n"
    printf "     -p passwd  Specify a PostgreSQL password.\\n"
    printf "     -k key1    Specify an eWallet secret key.\\n"
    printf "     -K key2    Specify a local ledger secret key.\\n"
    printf "     -E key2    Specify an external ledger secret key.\\n"
    printf "     -f env     Specify an env file.\\n"
    printf "\\n"
}

ARGS=$(getopt -s sh hdi:n:p:k:K:f: "$@" 2>/dev/null)

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "$ARGS"

IMAGE_NAME=""
POSTGRES_PASSWORD=""
EXTERNAL_NETWORK=""
EWALLET_SECRET_KEY=""
LOCAL_LEDGER_SECRET_KEY=""
EXTERNAL_LEDGER_SECRET_KEY=""
DEV_MODE=0

while true; do
    case "$1" in
        -i ) IMAGE_NAME=$2;              shift; shift;;
        -n ) EXTERNAL_NETWORK=$2;        shift; shift;;
        -p ) POSTGRES_PASSWORD=$2;       shift; shift;;
        -k ) EWALLET_SECRET_KEY=$2;      shift; shift;;
        -K ) LOCAL_LEDGER_SECRET_KEY=$2; shift; shift;;
        -E ) EXTERNAL_LEDGER_SECRET_KEY=$2; shift; shift;;
        -f ) ENV_FILE=$2;                shift; shift;;
        -d ) DEV_MODE=1;  shift;;
        -h ) print_usage; exit 2;;
        *  ) break;;
    esac
done

[ -z "$EWALLET_SECRET_KEY" ]      && EWALLET_SECRET_KEY=$(openssl rand -base64 32)
[ -z "$LOCAL_LEDGER_SECRET_KEY" ] && LOCAL_LEDGER_SECRET_KEY=$(openssl rand -base64 32)
[ -z "$EXTERNAL_LEDGER_SECRET_KEY" ] && EXTERNAL_LEDGER_SECRET_KEY=$(openssl rand -base64 32)
[ -z "$POSTGRES_PASSWORD" ]       && POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr '+/' '-_')

if [ -z "$IMAGE_NAME" ]; then
   if [ $DEV_MODE = 1 ]; then
       IMAGE_NAME="omisegoimages/ewallet-builder:v1.2"
   else
       IMAGE_NAME="omisego/ewallet:v1.1-dev"
   fi
fi

YML_SERVICES="
  postgres:
    environment:
      POSTGRESQL_PASSWORD: $POSTGRES_PASSWORD\
" # EOF

YML_SERVICES="
  ewallet:
    image: $IMAGE_NAME
    environment:
      DATABASE_URL: postgresql://postgres:$POSTGRES_PASSWORD@postgres:5432/ewallet
      LOCAL_LEDGER_DATABASE_URL: postgresql://postgres:$POSTGRES_PASSWORD@postgres:5432/local_ledger
      EXTERNAL_LEDGER_DATABASE_URL: postgresql://postgres:$POSTGRES_PASSWORD@postgres:5432/external_ledger
      EWALLET_SECRET_KEY: $EWALLET_SECRET_KEY
      LOCAL_LEDGER_SECRET_KEY: $LOCAL_LEDGER_SECRET_KEY\
      EXTERNAL_LEDGER_SECRET_KEY: $EXTERNAL_LEDGER_SECRET_KEY\
" # EOF

if [ -n "$ENV_FILE" ]; then
    YML_SERVICES="$YML_SERVICES
    env_file:
      - .env\
" # EOF
fi

if [ $DEV_MODE = 1 ]; then
    YML_SERVICES="$YML_SERVICES
    user: root
    volumes:
      - .:/app
      - ewallet-deps:/app/deps
      - ewallet-builds:/app/_build
      - ewallet-node:/app/apps/admin_panel/assets/node_modules
    working_dir: /app
    command:
      - mix
      - omg.server
    ports:
      - \"4000:4000\"\
" # EOF

    YML_VOLUMES="
  ewallet-deps:
  ewallet-builds:
  ewallet-node:\
" # EOF
fi

if [ -n "$EXTERNAL_NETWORK" ]; then
    YML_NETWORKS="
  intnet:
    external:
      name: $EXTERNAL_NETWORK\
" # EOF
fi

printf "version: \"3\"\\n"
if [ -n "$YML_SERVICES" ]; then printf "\\nservices:%s\\n" "$YML_SERVICES"; fi
if [ -n "$YML_NETWORKS" ]; then printf "\\nnetworks:%s\\n" "$YML_NETWORKS"; fi
if [ -n "$YML_VOLUMES" ];  then printf "\\nvolumes:%s\\n"  "$YML_VOLUMES";  fi
