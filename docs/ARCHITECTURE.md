# Architecture

## Goal

Run the untouched official Live for Speed build with low wrapper overhead on Linux.

## Runtime path

```text
application menu
  -> /usr/bin/lfs-linux-desktop (first-run decision, then exec)
  -> /usr/bin/lfs-linux
  -> /usr/lib/lfs-linux/lfs-linux-core
  -> audited Wine 11.15-1 (exact system package or private verified extraction)
  -> LFS.exe
  -> private DXVK d3d9.dll
  -> host Vulkan driver
```

First-run setup uses a terminal only while downloading and installing. It verifies the official NSIS archive, extracts its stock payload with 7-Zip without executing the installer stub, removes installer-only helper files, and verifies the resulting asset tree before installation. On later launches, the desktop helper replaces itself with the direct launcher. No wrapper daemon, container, Steam client, Bottles process, or web UI remains between Wine and LFS.

## State ownership

| Data | Default path | Owner |
|---|---|---|
| Wine prefix and official game | `~/.local/share/lfs-linux/prefix` | LFS and Wine |
| Audited Wine runtime and private DXVK DLL | `~/.local/share/lfs-linux/runtime` | wrapper |
| Download and shader cache | `~/.cache/lfs-linux` | wrapper and DXVK |
| Runtime logs | `~/.local/state/lfs-linux` | wrapper and DXVK |
| Launch lock | `$XDG_RUNTIME_DIR/lfs-linux-$UID` | wrapper |

The package manager owns only files under `/usr`. Package removal does not delete user data.

## Compatibility choices

The prefix is 64-bit. Audited Arch Wine 11.15-1 uses pure WoW64 and supports the 32-bit LFS executable. The wrapper accepts that exact package payload only. If the exact system package is unavailable, setup downloads its immutable Arch Linux Archive package, verifies its digest, extracts it privately, and validates every runtime file and link. Other Wine versions fail closed.

The wrapper deploys DXVK `x32/d3d9.dll` to `syswow64`. It sets a native-first `d3d9` override only for wrapper launches.

LFS does not use .NET or Wine's HTML engine. The prefix disables `mscoree` and `mshtml` so Wine never opens optional Mono or Gecko downloader dialogs during one-click setup.

The launcher always passes `/windowed=yes`. Users can switch modes in LFS with `Shift+F4`.

## Performance choices

- Direct native execution of the exact audited Wine runtime
- Direct host Vulkan loader and driver
- One D3D translation layer: DXVK
- No Gamescope or compositor wrapper by default
- Persistent DXVK shader cache
- Prefix-local processes only
- Bounded setup commands with prefix-scoped cleanup
- No update network request during launch
- No automatic game-file mutation

## Update model

`share/lfs-linux/release.env` is the single audited manifest. It pins upstream URLs, sizes, archive digests, the exact Wine package, and the immutable payload-manifest digests. The shipped LFS and Wine payload manifests cover every required non-player game file and every Wine runtime file or link.

`lfs-linux update-check` reads the official downloads page. It reports drift but never edits the game or manifest.

A release maintainer updates the installer, executable, required-asset, tree-size, and tree-count pins only after a clean extraction and behavioral run.

## Display policy for this workspace

All project GUI checks use Xephyr display `:111` with its Xauthority file. The nested display currently reports llvmpipe.

Xephyr proves isolated GUI behavior. It does not prove native GPU latency. Native performance claims must come from direct-host architecture or separate approved hardware measurements.
