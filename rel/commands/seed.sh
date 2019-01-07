#!/bin/sh

seed_spec=seed

while [ "$#" -gt 0 ]; do case $1 in
    -e|--e2e) seed_spec=seed_e2e;;
    *) echo "$0: illegal option -- $1"; exit 1;;
esac; shift; done

"$RELEASE_ROOT_DIR/bin/ewallet" command Elixir.EWallet.ReleaseTasks "${seed_spec}"
