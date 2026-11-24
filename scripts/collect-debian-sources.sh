#!/bin/bash
set -euo pipefail

output_dir=$1
shift
readarray -t packages < <(sort -u "$@")
(( ${#packages[@]} > 0 ))

source_lists=$(mktemp -d)
trap 'rm -rf "$source_lists"' EXIT
sed 's/^Types: deb$/Types: deb-src/' /etc/apt/sources.list.d/debian.sources \
    > "$source_lists/debian.sources"
apt_options=(-o Dir::Etc::sourcelist=/dev/null -o "Dir::Etc::sourceparts=$source_lists")

mkdir -p "$output_dir"
cd "$output_dir"
apt-get "${apt_options[@]}" update
apt-get "${apt_options[@]}" source --download-only --only-source "${packages[@]}"

source_descriptions=(*.dsc)
if (( ${#source_descriptions[@]} != ${#packages[@]} )) || [[ ! -f ${source_descriptions[0]} ]]; then
    echo 'The downloaded Debian sources do not match the package inventory.' >&2
    exit 1
fi
