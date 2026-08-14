#!/usr/bin/env bash
set -Eeuo pipefail

export LC_ALL=C
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR
VERSION="$(<"$ROOT_DIR/VERSION")"
readonly VERSION
readonly PROJECT_SLUG='live-for-speed-linux-launcher'
readonly ARCHIVE_NAME="$PROJECT_SLUG-$VERSION.tar.gz"
readonly OUTPUT_DIR="${1:-$ROOT_DIR/dist}"
readonly SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1786665600}"
readonly -a ENTRIES=(
  VERSION
  LICENSE
  Makefile
  README.md
  CONTRIBUTING.md
  SECURITY.md
  bin
  libexec
  share
  docs
  scripts
  tests
  website
)

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DIR/$ARCHIVE_NAME"
(
  cd "$ROOT_DIR"
  tar \
    --sort=name \
    --format=ustar \
    --mtime="@$SOURCE_DATE_EPOCH" \
    --owner=0 \
    --group=0 \
    --numeric-owner \
    --transform="s,^,$PROJECT_SLUG-$VERSION/," \
    -cf - "${ENTRIES[@]}" |
    gzip -n -9 >"$OUTPUT_DIR/$ARCHIVE_NAME"
)

printf '%s  %s\n' "$(sha256sum "$OUTPUT_DIR/$ARCHIVE_NAME" | awk '{print $1}')" "$OUTPUT_DIR/$ARCHIVE_NAME"
