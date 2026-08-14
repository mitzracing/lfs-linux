# Release Procedure

## Wrapper release

1. Run `make test`.
2. Build a staged filesystem with `make DESTDIR="$PWD/pkgroot" install`.
3. Validate the desktop file and AppStream metadata.
4. Build the AUR package from a real signed or immutable project tag.
5. Install the staged package in a disposable environment.
6. Run a clean `lfs-linux install`.
7. Run `lfs-linux doctor`.
8. Run a cold GUI launch on the project display.
9. Confirm DXVK, Vulkan device, audio stream, and clean exit.
10. Publish wrapper source only.

## Upstream pin update

Update `share/lfs-linux/release.env` as one change:

- LFS version
- installer filename and URL
- byte size
- installer SHA-256
- installed `LFS.exe` SHA-256 and byte size
- the complete immutable stock manifest name, size, SHA-256 digest, and entry count
- required helmet, track, and vehicle asset paths, sizes, and SHA-256 digests
- minimum extracted file count and byte size as secondary sanity checks
- prior audited executable digest in `LFS_UPGRADE_FROM_SHA256S` for safe in-place upgrades
- DXVK version, URL, size, archive SHA-256, and D3D9 DLL SHA-256 when applicable
- exact Wine package version, immutable archive URL, size, SHA-256 digest, and complete runtime-manifest pins

The wrapper extracts the verified NSIS archive with 7-Zip and does not execute the installer stub. Remove `$PLUGINSDIR` and `UninstallLFS.exe`, then regenerate the LFS manifest with `scripts/generate-payload-manifest.py lfs`. Extract the exact Wine package and regenerate its manifest with the `wine` profile. Review player-owned exclusions before accepting either manifest.

Delete a randomly selected immutable file that is not one of the separately pinned representative files. Confirm `doctor` and `launch` fail, `install` restores its exact hash, and player-owned paths remain byte-identical. Perform the same drift-and-reprovision check on one non-entry-point Wine DLL.

Then test an in-place upgrade from every digest listed in `LFS_UPGRADE_FROM_SHA256S`. Compare player-owned paths before and after the extraction merge, and confirm that the complete new stock tree passes validation. Remove a digest from the upgrade list when that path is no longer supported.

Then run the full wrapper release procedure.

Do not copy an existing user prefix into a release. A clean prefix is mandatory.

## AUR publication

The AUR recipe uses the deterministic archive created by `make release-archive`, not GitHub's generated source snapshot.

1. Run `make release-archive` twice and compare SHA-256 digests.
2. Confirm the digest equals `packaging/aur/PKGBUILD`.
3. Upload that exact archive as `live-for-speed-linux-<version>.tar.gz` on the matching GitHub release.
4. Run `makepkg --verifysource`.
5. Run `makepkg --cleanbuild --syncdeps` in a clean Arch environment.
6. Run `namcap` when available.
7. Generate `.SRCINFO` with `makepkg --printsrcinfo`.
8. Compare generated `.SRCINFO` with the committed file.
9. Inspect package contents for proprietary files and home paths.
10. Recheck that the AUR package name is available, then submit.

GitHub release publication and AUR submission require explicit owner approval.

## Rollback

Revert the wrapper package to the last verified tag. Do not downgrade or overwrite game-owned user data automatically.

If an upstream game update is incompatible, keep the prior pin only while its official URL and terms remain valid. Clearly report that status.
