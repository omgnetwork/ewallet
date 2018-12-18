#!/bin/sh

# shellcheck disable=SC2068
"$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks config $@
