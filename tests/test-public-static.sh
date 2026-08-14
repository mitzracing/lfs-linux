#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR

bash -n "$ROOT_DIR/bin/"* "$ROOT_DIR/libexec/lfs-linux-core" "$ROOT_DIR/scripts/"*.sh "$ROOT_DIR/tests/"*.sh
python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' "$ROOT_DIR/scripts/generate-payload-manifest.py"
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "$ROOT_DIR/bin/"* "$ROOT_DIR/libexec/lfs-linux-core" "$ROOT_DIR/scripts/"*.sh "$ROOT_DIR/tests/"*.sh
fi

# shellcheck source=/dev/null
source "$ROOT_DIR/share/lfs-linux/release.env"
[[ "$LFS_LINUX_VERSION" == "$(<"$ROOT_DIR/VERSION")" ]]
[[ "$LFS_INSTALLER_URL" == https://www.lfs.net/* ]]
[[ "$LFS_INSTALLER_SIZE" =~ ^[0-9]+$ ]]
[[ "$LFS_INSTALLER_SHA256" =~ ^[0-9a-f]{64}$ ]]
[[ "$LFS_EXE_SIZE" =~ ^[0-9]+$ ]]
[[ "$LFS_EXE_SHA256" =~ ^[0-9a-f]{64}$ ]]
lfs_stock_manifest="$ROOT_DIR/share/lfs-linux/$LFS_STOCK_MANIFEST_NAME"
[[ "$(stat -c %s "$lfs_stock_manifest")" == "$LFS_STOCK_MANIFEST_SIZE" ]]
[[ "$(sha256sum "$lfs_stock_manifest" | awk '{print $1}')" == "$LFS_STOCK_MANIFEST_SHA256" ]]
[[ "$(awk -F '\t' '$1 == "f" || $1 == "l" { count++ } END { print count + 0 }' "$lfs_stock_manifest")" == "$LFS_STOCK_MANIFEST_ENTRIES" ]]
grep -Fq $'\tdata/veh/F1.vob' "$lfs_stock_manifest"
[[ "$LFS_TREE_MIN_FILE_COUNT" =~ ^[0-9]+$ && "$LFS_TREE_MIN_FILE_COUNT" -ge 3000 ]]
[[ "$LFS_TREE_MIN_BYTES" =~ ^[0-9]+$ && "$LFS_TREE_MIN_BYTES" -ge 1000000000 ]]
for required_path in "$LFS_REQUIRED_HELMET_PATH" "$LFS_REQUIRED_TRACK_PATH" "$LFS_REQUIRED_VEHICLE_PATH"; do
  [[ "$required_path" != /* && "$required_path" != *'..'* ]]
done
[[ "$LFS_REQUIRED_HELMET_SIZE" =~ ^[0-9]+$ ]]
[[ "$LFS_REQUIRED_HELMET_SHA256" =~ ^[0-9a-f]{64}$ ]]
[[ "$LFS_REQUIRED_TRACK_SIZE" =~ ^[0-9]+$ ]]
[[ "$LFS_REQUIRED_TRACK_SHA256" =~ ^[0-9a-f]{64}$ ]]
[[ "$LFS_REQUIRED_VEHICLE_SIZE" =~ ^[0-9]+$ ]]
[[ "$LFS_REQUIRED_VEHICLE_SHA256" =~ ^[0-9a-f]{64}$ ]]
read -r -a previous_lfs_hashes <<<"$LFS_UPGRADE_FROM_SHA256S"
for previous_hash in "${previous_lfs_hashes[@]}"; do
  [[ "$previous_hash" =~ ^[0-9a-f]{64}$ ]]
done
[[ "$DXVK_ARCHIVE_URL" == https://github.com/doitsujin/dxvk/* ]]
[[ "$DXVK_ARCHIVE_SIZE" =~ ^[0-9]+$ ]]
[[ "$DXVK_ARCHIVE_SHA256" =~ ^[0-9a-f]{64}$ ]]
[[ "$DXVK_D3D9_X32_SIZE" =~ ^[0-9]+$ ]]
[[ "$DXVK_D3D9_X32_SHA256" =~ ^[0-9a-f]{64}$ ]]
[[ "$WINE_RUNTIME_VERSION" == '11.15-1' ]]
[[ "$WINE_VERSION_OUTPUT" == 'wine-11.15' ]]
[[ "$WINE_PACKAGE_URL" == https://archive.archlinux.org/packages/w/wine/* ]]
[[ "$WINE_PACKAGE_SIZE" =~ ^[0-9]+$ ]]
[[ "$WINE_PACKAGE_SHA256" =~ ^[0-9a-f]{64}$ ]]
wine_runtime_manifest="$ROOT_DIR/share/lfs-linux/$WINE_RUNTIME_MANIFEST_NAME"
[[ "$(stat -c %s "$wine_runtime_manifest")" == "$WINE_RUNTIME_MANIFEST_SIZE" ]]
[[ "$(sha256sum "$wine_runtime_manifest" | awk '{print $1}')" == "$WINE_RUNTIME_MANIFEST_SHA256" ]]
[[ "$(awk -F '\t' '$1 == "f" || $1 == "l" { count++ } END { print count + 0 }' "$wine_runtime_manifest")" == "$WINE_RUNTIME_MANIFEST_ENTRIES" ]]

"$ROOT_DIR/bin/lfs-linux" help | grep -Fq 'setup'
"$ROOT_DIR/bin/lfs-linux" help | grep -Fq 'update-check'
"$ROOT_DIR/bin/lfs-linux" help | grep -Fq 'verify-sources'
"$ROOT_DIR/bin/lfs-linux" help | grep -Fq 'remove'

community_icon="$ROOT_DIR/share/icons/hicolor/scalable/apps/io.github.mitzracing.live_for_speed_linux.svg"
(( $(stat -c %s "$community_icon") < 4096 ))
xmllint --noout "$community_icon"
if grep -Eq '<(text|image|script)([[:space:]]|>)|href=' "$community_icon"; then
  printf 'community icon contains text, scripts, or external assets\n' >&2
  exit 1
fi

desktop-file-validate "$ROOT_DIR/share/applications/io.github.mitzracing.live_for_speed_linux.desktop"
if command -v appstreamcli >/dev/null 2>&1; then
  appstreamcli validate --no-net "$ROOT_DIR/share/metainfo/io.github.mitzracing.live_for_speed_linux.metainfo.xml"
else
  xmllint --noout "$ROOT_DIR/share/metainfo/io.github.mitzracing.live_for_speed_linux.metainfo.xml"
fi

# No privileged game install and no hidden auto-update path.
if grep -R -nE '^[[:space:]]*sudo[[:space:]]' "$ROOT_DIR/bin" "$ROOT_DIR/libexec" "$ROOT_DIR/scripts"; then
  printf 'privileged runtime command found\n' >&2
  exit 1
fi
if grep -R -nE '(curl|wget).*(launch_game|case.*launch)' "$ROOT_DIR/libexec/lfs-linux-core"; then
  printf 'network command found in launch hot path\n' >&2
  exit 1
fi
grep -Fq '7z x -y' "$ROOT_DIR/libexec/lfs-linux-core"
grep -Fq "verify_game_tree \"\$unpack\" 'extracted LFS'" "$ROOT_DIR/libexec/lfs-linux-core"
grep -Fq "verify_payload_manifest \"\$label immutable stock payload\"" "$ROOT_DIR/libexec/lfs-linux-core"
if grep -Eq 'LFS_INSTALLER_ACCEPTED_EXIT_CODES|ALLOW_UNTESTED_WINE|WINE_TESTED_MAJOR|wine>=10' "$ROOT_DIR/libexec/lfs-linux-core" "$ROOT_DIR/share/lfs-linux/release.env"; then
  printf 'unbounded installer or Wine-version acceptance remains in the public core\n' >&2
  exit 1
fi

# Public package tree must not contain proprietary Windows payloads.
if find "$ROOT_DIR" -path "$ROOT_DIR/legacy" -prune -o -type f \
  \( -iname '*.exe' -o -iname '*.dll' -o -iname '*.msi' -o -iname '*.zip' \) -print -quit | grep -q .; then
  printf 'proprietary or binary runtime payload found in public tree\n' >&2
  exit 1
fi

if [[ "${LFS_LINUX_SOURCE_ARCHIVE:-0}" != '1' ]]; then
  # Flathub stays policy-gated until upstream authorization.
  [[ ! -e "$ROOT_DIR/packaging/flathub/io.github.mitzracing.live_for_speed_linux.yml" ]]
  grep -Fq 'No Flatpak manifest exists here by design.' "$ROOT_DIR/packaging/flathub/README.md"

  # AUR recipe must use the exact audited Wine and a pinned project release asset.
  grep -Fq "'wine=11.15-1'" "$ROOT_DIR/packaging/aur/PKGBUILD"
  if grep -Eq 'ALLOW_UNTESTED_WINE|WINE_TESTED_MAJOR|wine>=10' "$ROOT_DIR/packaging/aur/PKGBUILD"; then
    printf 'broad Wine dependency remains in the AUR recipe\n' >&2
    exit 1
  fi
  if grep -Fq 'SKIP' "$ROOT_DIR/packaging/aur/PKGBUILD"; then
    printf 'AUR source checksum is not pinned\n' >&2
    exit 1
  fi
  grep -Fq "releases/download/v\$pkgver/\$_source_name-\$pkgver.tar.gz" "$ROOT_DIR/packaging/aur/PKGBUILD"
  grep -Eq "^sha256sums=\('[0-9a-f]{64}'\)$" "$ROOT_DIR/packaging/aur/PKGBUILD"
fi

printf '[PASS] syntax, manifest pins, metadata, stock-game boundary, and publication gates\n'
