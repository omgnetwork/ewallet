#!/bin/sh

# Copyright 2019 OmiseGO Pte Ltd
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
    printf "     --settings  Seeds the settings.\\n"
    printf "\\n"
}

ARGS=$(getopt -s sh -l e2e -l sample -l settings hes "$@" 2>/dev/null)

# shellcheck disable=SC2181
if [ $? != 0 ]; then
    print_usage
    exit 1
fi

eval set -- "$ARGS"

SEED_SPEC=run

while true; do
    case "$1" in
        -- ) shift; break;;
        -e | --e2e )    SEED_SPEC=run_e2e; shift;;
        -s | --sample ) SEED_SPEC=run_sample; shift;;
        --settings )    SEED_SPEC=run_settings; shift;;
        -h ) print_usage; exit 2;;
        *  ) break;;
    esac
done

exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks.Seed "$SEED_SPEC"
