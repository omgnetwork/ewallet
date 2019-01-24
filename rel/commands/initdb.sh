#!/bin/sh

set +e

print_usage() {
    printf "Usage: bin/ewallet initdb [OPTS]\\n"
    printf "\\n"
    printf "Create and upgrade the database.\\n"
    printf "\\n"
    printf "OPTS:\\n"
    printf "\\n"
    printf "     -h          Prints this help.\\n"
    printf "\\n"
}

ARGS=$(getopt -s sh h "$@" 2>/dev/null)

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "$ARGS"

while true; do
    case "$1" in
        -h ) print_usage; exit 2;;
        -* ) print_usage; exit 1;;
        *  ) break;;
    esac
done

exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks initdb
