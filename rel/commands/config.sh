#!/bin/sh

# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
    printf "     -h           Prints this help.\\n"
    printf "     -m --migrate Migrate environment variable configurations to the database.\\n"
    printf "\\n"
}

run_set() {
    # We don't want to deal with argument parsing again in Elixir. No, just no.
    # Let's sidestep all issues by passing the already-parsed value as Base64
    # and let the release task decode it.
    KEY="$(printf "%s" "$1" | base64)"; shift
    VALUE="$(printf "%s" "$1" | base64)"; shift
    exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks.Config run "$KEY" "$VALUE"
}

run_migrate() {
    # Run the settings seed before migrating so users don't have to know to run this first.
    if ! $RELEASE_ROOT_DIR/bin/ewallet command Elixir.EWallet.ReleaseTasks.Seed run_settings; then
        printf "The error occurred during seeding settings data.\\n"
        exit 1
    fi

    MIGRATION_FN = "run_ask_confirm"

    if [ "$ASK_CONFIRM" = true ]; then
      MIGRATION_FN = "run_skip_confirm"
    fi

    exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks.ConfigMigration "$MIGRATION_FN"
}

ARGS=$(getopt -s sh -l migrate -l yes -l assume_yes myh "$@" 2>/dev/null)

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "$ARGS"

ACTION=set
ASK_CONFIRM=true

while true; do
    case "$1" in
        -m | --migrate ) ACTION=migrate; shift;;
        -y | --yes | --assume_yes ) ASK_CONFIRM=false; shift;;
        -h ) print_usage; exit 2;;
        -- ) shift; break;;
        *  ) break;;
    esac
done

case "$ACTION" in
    set )     run_set;;
    migrate ) run_migrate;;
    * )       print_usage; exit 1;;
esac
