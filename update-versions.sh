#!/bin/sh
BASE_DIR=$(cd "$(dirname "$0")" || exit; pwd -P)
FILE_LIST="/tmp/update_version_files"

if [ -z "$1" ]; then
    printf "Usage: %s NEW_VERSION\\n" "$0"
    exit 2
fi

trap 'rm $FILE_LIST' 0 1 2 3 6 14 15
find "$BASE_DIR/apps" -not -name "$(printf "*\\n*")" -iname "mix.exs" > "$FILE_LIST"

while IFS= read -r file; do
    NEW_VERSION=$1 awk '
        m = match($0, "^([\ ]+version:[\ ]+)") {
          print substr($0, RSTART, RLENGTH-1) " \"" ENVIRON["NEW_VERSION"] "\","
        } ! m { print }
    ' < "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
done < "$FILE_LIST"
