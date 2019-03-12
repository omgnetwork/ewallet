#!/bin/sh

set -e

echo_info() {
    printf "\\033[0;34m%s\\033[0;0m\\n" "$1"
}

echo_warn() {
    printf "\\033[0;33m%s\\033[0;0m\\n" "$1"
}


## Sanity check
##

if [ -z "$CIRCLE_GPG_KEY" ] ||
       [ -z "$CIRCLE_GPG_OWNERTRUST" ] ||
       [ -z "$GCP_KEY_FILE" ] ||
       [ -z "$GCP_ACCOUNT_ID" ] ||
       [ -z "$GCP_REGION" ] ||
       [ -z "$GCP_ZONE" ] ||
       [ -z "$GCP_CLUSTER_ID" ]; then
    echo_warn "Deploy credentials not present, skipping deploy."
    exit 0
fi


## GPG
##

GPGFILE=$(mktemp)
trap 'rm -f $GPGFILE' 0 1 2 3 6 14 15
echo "$CIRCLE_GPG_KEY" | base64 -d | gunzip > "$GPGFILE"
gpg --import "$GPGFILE"
printf "%s\\n" "$CIRCLE_GPG_OWNERTRUST" | gpg --import-ownertrust


## GCP
##

GCPFILE=$(mktemp)
trap 'rm -f $GCPFILE' 0 1 2 3 6 14 15
echo "$GCP_KEY_FILE" | base64 -d > "$GCPFILE"

gcloud auth activate-service-account --key-file="$GCPFILE"
gcloud config set project "$GCP_ACCOUNT_ID"
gcloud config set compute/region "$GCP_REGION"
gcloud config set compute/zone "$GCP_ZONE"
gcloud container clusters get-credentials --region="$GCP_REGION" "$GCP_CLUSTER_ID"


## Cloning
##

mkdir -p ~/.ssh
ssh-keyscan github.com >> ~/.ssh/known_hosts

git init ~/deploy
cd ~/deploy || exit 1
git remote add origin "git@github.com:omisego/deploy.git"
git config core.sparsecheckout true

cat <<EOF >> ~/deploy/.git/info/sparse-checkout
.gitmodules
kapitan/components/*
kapitan/inventory/classes/*
kapitan/inventory/targets/demo-staging.yml
kapitan/secrets/default/*
kapitan/secrets/demo-staging/*
kapitan/share/*
vendor/github.com/omisego/*
vendor/github.com/ksonnet/*
EOF

git pull --depth 1 origin master
git submodule update --init vendor/github.com/omisego/charts
git submodule update --init vendor/github.com/ksonnet/ksonnet-lib
git submodule update --init vendor/github.com/deepmind/kapitan


## Init Helm
##

cd ~/deploy || exit 1
helm init --client-only
helm dependency update vendor/github.com/omisego/charts/ewallet


## Compile Kapitan
##

cd ~/deploy/kapitan || exit 1

TARGET="inventory/targets/demo-staging.yml"
NEW_TAG="$(printf "%s" "$CIRCLE_SHA1" | head -c 8)" awk '
  m = match($0, "^([\ ]+tag:[\ ]+)") {
  print substr($0, RSTART, RLENGTH-1) " \"" ENVIRON["NEW_TAG"] "\""
} ! m { print }' < "$TARGET" > "$TARGET.tmp"
mv "$TARGET.tmp" "$TARGET"

kapitan compile -J ./ \
  ../vendor/github.com/ksonnet/ksonnet-lib \
  ../vendor/github.com/deepmind/kapitan/kapitan/lib


## Deploy!
##

sh compiled/demo-staging/ewallet/apply.sh
