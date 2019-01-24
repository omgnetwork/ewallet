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

ARGS=$(getopt -s sh -l migrate -l yes -l assume_yes myh "$@" 2>/dev/null)

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "$ARGS"

ACTION=set

while true; do
    case "$1" in
        -- ) shift; break;;
        -h ) print_usage; exit 2;;
        -m | --migrate ) ACTION=migrate; shift;;
        -* ) print_usage; exit 1;;
        *  ) break;;
    esac
done


if [ $ACTION = migrate ]; then
    $RELEASE_ROOT_DIR/bin/ewallet command Elixir.EWallet.ReleaseTasks.Seed run_settings &&
    exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks.ConfigMigration run
elif [ $ACTION = set ]; then
    # We don't want to deal with argument parsing again in Elixir. No, just no.
    # Let's sidestep all issues by passing the already-parsed value as Base64
    # and let the release task decode it.
    KEY="$(printf "%s" "$1" | base64)"; shift
    VALUE="$(printf "%s" "$1" | base64)"; shift
    exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks.Config run "$KEY" "$VALUE"
else
    print_usage
    exit 2
fi
