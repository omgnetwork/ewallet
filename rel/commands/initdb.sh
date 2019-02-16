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
        -- ) shift; break;;
        -h ) print_usage; exit 2;;
        *  ) break;;
    esac
done

exec "$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks.InitDB run
