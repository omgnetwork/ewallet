#!/bin/sh

BASE_DIR=$(cd "$(dirname "$0")" || exit; pwd -P)
FILE_LIST="/tmp/update_version_files"

print_usage() {
    printf 2>&1 "\
Usage: %s [-a] NEW_VERSION

Update version string in mix.exs and config.exs with NEW_VERSION
by scanning lines with version: string. This script will try its
best to retain the indention of the original string.

If -a is given, it will try to determine the version from current
branch and Git version, suitable for running in Ci environment.
" "$0"
}

OPTIND=1
VERSION=
AUTO=0

while getopts "a" opt; do
    case "$opt" in
        a ) AUTO=1;;
        * ) print_usage; exit 1;;
    esac
done

shift $((OPTIND-1))
if [ "${1:-}" = "--" ]; then
    shift
fi

VERSION=$1

if [ "$AUTO" = 1 ]; then
    if ! command -v git >/dev/null; then
        printf 2>&1 "Git is required to auto-generating version\\n"
        exit 1
    fi

    # git describe --tags will generate a version of the TAG, if HEAD is a tag,
    # or a TAG-NN-gSHA where NN is the number of commits since the last tag
    # and SHA256 is an abbrev-rev of HEAD, e.g. v1.2.0-pre.0-17-gaceb325f
    VERSION=$(git describe --tags)
    VERSION=${VERSION#v*}

    printf 2>&1 "Using %s as the current version.\\n" "$VERSION"
elif [ -z "$VERSION" ]; then
    print_usage
    exit 2
fi

# POSIX sh doesn't supported piping a list of files into another command
# so we need to use intermediate file list and read from it.
trap 'rm $FILE_LIST' 0 1 2 3 6 14 15
find "$BASE_DIR/apps" \
     -not -name "$(printf "*\\n*")" \
     \( -iname "mix.exs" -or -iname "config.exs" \) \
> "$FILE_LIST"

printf 2>&1 "Updating versions...\\n"

while IFS= read -r file; do
    if ! grep -E -q "^[\ ]+version:" "$file"; then
        continue
    fi

    printf 2>&1 "* %-40s" "${file#$BASE_DIR/*}..."
    NEW_VERSION=$VERSION awk '
        m = match($0, "^([ ]+version:[ ]+)") {
          print substr($0, RSTART, RLENGTH-1) " \"" ENVIRON["NEW_VERSION"] "\","
        } ! m { print }
    ' < "$file" > "$file.tmp"

    mv "$file.tmp" "$file"
    printf 2>&1 " OK\\n"
done < "$FILE_LIST"
