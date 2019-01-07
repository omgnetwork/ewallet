#!/bin/sh
BASE_DIR=$(cd "$(dirname "$0")" || exit; pwd -P)
FILE_LIST="/tmp/update_version_files"

if [ -z "$1" ]; then
    printf "Usage: %s NEW_VERSION\\n\\n" "$0"
    printf "Update version string in mix.exs and config.exs with NEW_VERSION\\n"
    printf "by scanning lines with version: string. This script will try its\\n"
    printf "best to retain the indention of the original string.\\n"
    exit 2
fi

# POSIX sh doesn't supported piping a list of files into another command
# so we need to use intermediate file list and read from it.
trap 'rm $FILE_LIST' 0 1 2 3 6 14 15
find "$BASE_DIR/apps" \
     -not -name "$(printf "*\\n*")" \
     \( -iname "mix.exs" -or -iname "config.exs" \) \
> "$FILE_LIST"

printf "Updating versions...\\n"

while IFS= read -r file; do
    if ! grep -E -q "^[\ ]+version:" "$file"; then
        continue
    fi

    printf "* %-40s" "${file#$BASE_DIR/*}..."
    NEW_VERSION=$1 awk '
        m = match($0, "^([\ ]+version:[\ ]+)") {
          print substr($0, RSTART, RLENGTH-1) " \"" ENVIRON["NEW_VERSION"] "\","
        } ! m { print }
    ' < "$file" > "$file.tmp"

    mv "$file.tmp" "$file"
    printf " OK\\n"
done < "$FILE_LIST"
