#!/bin/sh

set +e

print_usage() {
    printf "Usage: bin/ewallet config [OPTS] KEY VALUE\\n"
    printf "\\n"
    printf "Update the eWallet configuration in the database.\\n"
    printf "\\n"
    printf "This command uses POSIX sh shell escaping to handle argument\\n"
    printf "splitting, this means you MUST escape quotes if it was intended\\n"
    printf "as part of a configuration value. For example:\\n"
    printf "\\n"
    printf "     bin/ewallet config example \"{\\\"key\\\": \\\"value\\\"}\"\\n"
    printf "\\n"
    printf "Alternatively, use a single quote:\\n"
    printf "\\n"
    printf "     bin/ewallet config example '{\"key\": \"value\"}'\\n"
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
        -- ) shift; break;;
        *  ) break;;
    esac
done

if [ $# -lt 2 ]; then
    print_usage
    exit 1
fi

# We don't want to deal with argument parsing again in Elixir. No, just no.
# Let's sidestep all issues by passing the already-parsed value as Base64
# and let the release task decode it.

KEY="$(printf "%s" "$1" | base64 | tr -d "\n")"; shift
VALUE="$(printf "%s" "$1" | base64 | tr -d "\n")"; shift

exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks config_base64 "$KEY" "$VALUE"
