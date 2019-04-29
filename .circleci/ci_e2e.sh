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

REPOSITORY_URL="$CIRCLE_REPOSITORY_URL"

if [ -z "$REPOSITORY_URL" ]; then
    REPOSITORY_URL="https://github.com/omisego/ewallet.git"
fi

if [ -z "$GCS_BUCKET" ] ||
       [ -z "$GCS_CREDENTIALS" ] ||
       [ -z "$AWS_BUCKET" ] ||
       [ -z "$AWS_REGION" ] ||
       [ -z "$AWS_ACCESS_KEY_ID" ] ||
       [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo_warn "E2E credentials is not present, skipping E2E."
    exit 0
fi

if [ -z "$IMAGE_NAME" ]; then
    echo_warn "IMAGE_NAME not present, failing."
    exit 1
fi


## Preflight
##

cat <<EOF > .env
E2E_HTTP_HOST=http://ewallet:4000
E2E_SOCKET_HOST=ws://ewallet:4000
E2E_TEST_ADMIN_EMAIL=$(openssl rand -hex 4)@example.com
E2E_TEST_ADMIN_PASSWORD=$(openssl rand -base64 24 | tr '+/' '-_')
E2E_TEST_ADMIN_1_EMAIL=$(openssl rand -hex 4)@example.com
E2E_TEST_ADMIN_1_PASSWORD=$(openssl rand -base64 24 | tr '+/' '-_')
E2E_TEST_USER_EMAIL=$(openssl rand -hex 4)@example.com
E2E_TEST_USER_PASSWORD=$(openssl rand -base64 24 | tr '+/' '-_')
EOF

sh docker-gen.sh -i "$IMAGE_NAME" -n net0 -f .env > docker-compose.override.yml


## Dependent services
##

docker network create net0
docker-compose up -d postgres mail


## Configure eWallet
##

docker-compose run --rm ewallet sh <<EOF >/dev/null 2>&1
bin/ewallet initdb
bin/ewallet seed -e
bin/ewallet config base_url http://ewallet:4000
bin/ewallet config email_adapter smtp
bin/ewallet config smtp_host mail
bin/ewallet config smtp_port 1025
bin/ewallet config aws_bucket "$AWS_BUCKET"
bin/ewallet config aws_region "$AWS_REGION"
bin/ewallet config aws_access_key_id "$AWS_ACCESS_KEY_ID"
bin/ewallet config aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
bin/ewallet config gcs_bucket "$GCS_BUCKET"
EOF

# Use printf/awk to unescape the string with double escaping.
unescaped_gcs_creds="$(printf "%b" "$GCS_CREDENTIALS" | awk '{ gsub("\\\\\"", "\""); print $0 }')"
docker-compose run --rm ewallet config gcs_credentials "$unescaped_gcs_creds" >/dev/null 2>&1


## Running E2E
##

_merge_base="master"
_branches="$(git ls-remote -h --refs git@github.com:omisego/ewallet 'v*' | awk '{ print $2 }' | sort -r)"

for _branch in "refs/heads/master" $_branches; do
    _branch="${_branch#refs/heads/*}"
    if [ "$(git merge-base --fork-point "origin/$_branch")" != "" ]; then
        _merge_base="$_branch"
        break
    fi
done

echo_info "Detected $_merge_base as merge base."

_e2e_repo="https://github.com/omisego/e2e.git"
_e2e_branch="ewallet/$_merge_base"

if [ "$(git ls-remote $_e2e_repo "$_e2e_branch")" = "" ]; then
  _e2e_branch="master"
fi

git clone --depth 1 -b "$_e2e_branch" https://github.com/omisego/e2e.git ~/e2e
echo_info "Running E2E from $_e2e_branch branch"

docker-compose up -d ewallet
trap "docker-compose logs ewallet" 0 1 2 3 6 14 15

docker run -i -v "$HOME/e2e:/e2e" --network net0 --env-file .env --rm python:3.7-alpine sh <<EOF
cd /e2e
pip3 install pipenv==2018.11.26
pipenv install
pipenv run robot tests
EOF
