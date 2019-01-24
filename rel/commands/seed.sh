#!/bin/sh

set +e

print_usage() {
    printf "Usage: bin/ewallet seed [OPTS]\\n"
    printf "\\n"
    printf "Seeds the database with initial data for production, testing\\n"
    printf "and evaluation purpose. This command does not attempt to\\n"
    printf "detect whether the database has already been seeded or not and\\n"
    printf "is expected to be run only once after running initdb.\\n"
    printf "\\n"
    printf "OPTS:\\n"
    printf "\\n"
    printf "     -h          Prints this help.\\n"
    printf "     -e --e2e    Seeds the end-to-end testing data.\\n"
    printf "     -s --sample Seeds the sample data.\\n"
    printf "\\n"
}

ARGS=$(getopt -s sh -l e2e -l sample hes "$@" 2>/dev/null)

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "$ARGS"

SEED_SPEC=seed

while true; do
    case "$1" in
        -e | --e2e )    SEED_SPEC=seed_e2e; shift;;
        -s | --sample ) SEED_SPEC=seed_sample; shift;;
        -h ) print_usage; exit 2;;
        -* ) print_usage; exit 1;;
        *  ) break;;
    esac
done

exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks "$SEED_SPEC"
