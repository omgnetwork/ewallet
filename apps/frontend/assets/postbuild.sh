#!/bin/sh

echo "Running postbuild steps ..."

cd ..

rm -rf priv/static

mkdir -p priv/static

cp -r assets/build/* priv/static

rm -rf assets/build

cd assets

echo "Postbuild steps complete."
