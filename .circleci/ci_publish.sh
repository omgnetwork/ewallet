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

if [ -z "$DOCKER_PASS" ] || [ -z "$DOCKER_USER" ]; then
    echo_warn "Docker credentials is not present, skipping publish."
    exit 0
fi

if [ -z "$IMAGE_NAME" ]; then
    echo_warn "IMAGE_NAME not present, failing."
    exit 1
fi


## Generate tags
##

if [ -n "$CIRCLE_SHA1" ]; then
    _shortref="$(printf "%s" "$CIRCLE_SHA1" | head -c 8)"
    _image_tag="$_shortref"
fi

if [ -n "$CIRCLE_TAG" ]; then
    _ver="${CIRCLE_TAG#*v}"

    # Given a v1.0.0-pre.1 tag, this will generate:
    # - 1.0
    # - 1.0.0-pre
    # - 1.0.0-pre.1
    while true; do
        case "$_ver" in
            *.* )
                _image_tag="$_ver $_image_tag"
                _ver="${_ver%.*}"
                ;;
            * )
                break;;
        esac
    done

    # In case the commit is HEAD of latest version branch, also tag stable.
    if [ -n "$CIRCLE_REPOSITORY_URL" ] && [ -n "$CIRCLE_SHA1" ]; then
        _stable_head="$(
            git ls-remote --heads "$CIRCLE_REPOSITORY_URL" "v*" |
            awk '/refs\/heads\/v[0-9]+\.[0-9]+$/ { LH=$1 } END { print LH }'
        )"

        if [ "$CIRCLE_SHA1" = "$_stable_head" ]; then
            _image_tag="$_image_tag stable"
        fi
    fi
else
    case "$CIRCLE_BRANCH" in
        master ) _image_tag="$_image_tag latest";;
        v*     ) _image_tag="$_image_tag ${CIRCLE_BRANCH#*v}-dev";;
        *      ) ;;
    esac
fi


## Publishing
##

if [ -f "$HOME/caches/docker-layers.tar" ]; then
    docker load -i "$HOME/caches/docker-layers.tar"
fi

printf "%s\\n" "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

for tag in $_image_tag; do
    echo_info "Publishing Docker image as $IMAGE_NAME:$tag"
    docker tag "$IMAGE_NAME" "$IMAGE_NAME:$tag"
    docker push "$IMAGE_NAME:$tag"
done
