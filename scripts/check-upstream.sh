#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ROOT_DIR
export LFS_LINUX_DATA_DIR="$ROOT_DIR/share/lfs-linux"
export LFS_LINUX_LIBEXEC_DIR="$ROOT_DIR/libexec"
exec "$ROOT_DIR/bin/lfs-linux" update-check
