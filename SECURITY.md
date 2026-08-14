# Security Policy

## Supported versions

Only the latest `lfs-linux` release receives security fixes.

## Report a vulnerability

Do not open a public issue for a vulnerability that exposes credentials, account data, arbitrary code execution, or unsafe update behavior.

Contact the maintainers through [GitHub private vulnerability reporting](https://github.com/mitzracing/lfs-linux/security/advisories/new). Do not publish sensitive proof data.

Include:

- wrapper version
- distribution and Wine version
- affected command
- minimal reproduction
- expected security boundary

Do not include an LFS password, unlock code, Wine registry, or complete home path.

## Trust model

The wrapper processes three upstream binary inputs:

1. The official LFS installer archive from `lfs.net`
2. The exact Arch Wine 11.15-1 package from the immutable Arch Linux Archive
3. The official DXVK release archive from GitHub

The release manifest pins byte sizes and SHA-256 digests. Changed inputs fail closed. The wrapper extracts the verified LFS NSIS archive with 7-Zip instead of executing its installer stub. Shipped payload manifests verify every immutable non-player game file and every Wine runtime file or link. The wrapper later executes only the verified stock `LFS.exe` through that exact Wine payload.

The wrapper does not sandbox Wine. Wine applications can access host files available to the user. The private prefix isolates configuration and processes, not filesystem authority.

## Update policy

The wrapper does not update during launch. `update-check` performs a read-only check and never changes pins.

Maintainers review each upstream update. Automated pull requests can report new versions but must not merge or publish them automatically.
