#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR
VERSION="$(<"$ROOT_DIR/VERSION")"
readonly VERSION
ARCHIVE_ROOT="live-for-speed-linux-launcher-$VERSION"
readonly ARCHIVE_ROOT
TMP_ROOT="$(mktemp -d /tmp/lfs-linux-release.XXXXXX)"
readonly TMP_ROOT
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/one" "$TMP_ROOT/two"
"$ROOT_DIR/scripts/build-release-archive.sh" "$TMP_ROOT/one" >"$TMP_ROOT/one.sha"
"$ROOT_DIR/scripts/build-release-archive.sh" "$TMP_ROOT/two" >"$TMP_ROOT/two.sha"
archive_one="$(find "$TMP_ROOT/one" -type f -name '*.tar.gz' -print -quit)"
archive_two="$(find "$TMP_ROOT/two" -type f -name '*.tar.gz' -print -quit)"
[[ -n "$archive_one" && -n "$archive_two" ]]
archive_hash="$(sha256sum "$archive_one" | awk '{print $1}')"
[[ "$archive_hash" == "$(sha256sum "$archive_two" | awk '{print $1}')" ]]
if [[ -f "$ROOT_DIR/packaging/aur/PKGBUILD" ]]; then
  pinned_hash="$(grep -Eo "sha256sums=\\('[0-9a-f]{64}'\\)" "$ROOT_DIR/packaging/aur/PKGBUILD" | grep -Eo '[0-9a-f]{64}')"
  [[ "$archive_hash" == "$pinned_hash" ]]
fi

listing="$(tar -tzf "$archive_one")"
grep -Fq "$ARCHIVE_ROOT/bin/lfs-linux" <<<"$listing"
grep -Fq "$ARCHIVE_ROOT/bin/lfs-linux-desktop" <<<"$listing"
grep -Fq "$ARCHIVE_ROOT/libexec/lfs-linux-core" <<<"$listing"
if grep -Eq '(^|/)(legacy|artifacts|\.pi-glla)(/|$)' <<<"$listing"; then
  printf 'local evidence entered release archive\n' >&2
  exit 1
fi
if grep -Ei '\.(exe|dll|msi|png)$' <<<"$listing"; then
  printf 'runtime or proprietary payload entered release archive\n' >&2
  exit 1
fi

tar -xzf "$archive_one" -C "$TMP_ROOT"
archive_dir="$TMP_ROOT/$ARCHIVE_ROOT"
LFS_LINUX_SOURCE_ARCHIVE=1 "$archive_dir/tests/test-public-static.sh" >/dev/null
"$archive_dir/tests/test-public-core.sh" >/dev/null
"$archive_dir/tests/test-website.sh" >/dev/null
make -C "$archive_dir" DESTDIR="$TMP_ROOT/pkgroot" PREFIX=/usr install >/dev/null
"$archive_dir/tests/test-package-boundary.sh" "$TMP_ROOT/pkgroot" >/dev/null

printf '[PASS] release archive is deterministic, self-testing, and excludes local/proprietary evidence\n'
