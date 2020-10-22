#!/bin/sh

echo "Running postbuild steps ..."

rm -rf ../priv/static

mkdir ../priv/static

cp -r build/* ../priv/static

rm -rf build

echo "Postbuild steps complete."
