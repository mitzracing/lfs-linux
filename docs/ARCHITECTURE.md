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
  -> private DXVK d3d11.dll + dxgi.dll
  -> host Vulkan driver
```

First-run setup uses a terminal only while downloading and installing. It verifies the official NSIS archive, extracts its outer payload and every pinned nested 7z payload without executing the installer stub, removes installer-only helper files, and verifies the resulting asset tree before installation. On later launches, the desktop helper replaces itself with the direct launcher. No wrapper daemon, container, Steam client, Bottles process, or web UI remains between Wine and LFS.

## State ownership

| Data | Default path | Owner |
|---|---|---|
| Wine prefix and official game | `~/.local/share/lfs-linux/prefix` | LFS and Wine |
| Audited Wine runtime and private DXVK archive | `~/.local/share/lfs-linux/runtime` | wrapper |
| Download and shader cache | `~/.cache/lfs-linux` | wrapper and DXVK |
| Runtime logs | `~/.local/state/lfs-linux` | wrapper and DXVK |
| Launch lock | `$XDG_RUNTIME_DIR/lfs-linux-$UID` | wrapper |

The package manager owns only files under `/usr`. Package removal does not delete user data.

## Compatibility choices

The prefix is 64-bit. Audited Arch Wine 11.15-1 uses pure WoW64 and supports the 32-bit LFS executable. The wrapper accepts that exact package payload only. If the exact system package is unavailable, setup downloads its immutable Arch Linux Archive package, verifies its digest, extracts it privately, and validates every runtime file and link. Other Wine versions fail closed.

LFS 0.8C19 imports D3D11 and DXGI. The wrapper deploys audited DXVK `x32/d3d11.dll` and `x32/dxgi.dll` to `syswow64`, then sets native-first `d3d11` and `dxgi` overrides only for wrapper launches. Upgrade removes the obsolete private `d3d9.dll` and override from v0.1.6.

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

`share/lfs-linux/release.env` is the single audited manifest. It pins upstream URLs, sizes, archive digests, the exact Wine package, and all payload-manifest digests. The nested manifest validates each of the 52 inner LFS archives before extraction. A seed manifest then validates all 4,841 extracted official files before installation. The runtime stock manifest covers every immutable non-player file; mutable AI knowledge, training content, profiles, setups, layouts, replays, screenshots, and similar player paths are intentionally outside it. The Wine manifest covers every runtime file or link.

`lfs-linux update-check` reads the official downloads page and models old-graphics stable and new-graphics public-test channels separately. It parses the exact public-test installer build. Matching pins return 0; a newer build, channel change, or installer-name drift returns 2 with an actionable wrapper-update message. It never edits the game or manifest and never runs in the launch path.

A release maintainer updates the installer, executable, nested archives, required assets, tree size, and tree count only after clean extraction, complete manifest generation, migration drills, and a behavioral run.

## Player-safe migration

An existing tree is classified before mutation:

- complete target stock: repair in place from verified staging while preserving player-owned paths
- approved predecessor: require both its complete immutable migration manifest and approved `LFS.exe` digest; mutable AI knowledge and training data remain outside that manifest
- unknown or self-updated tree: stop before mutation and require a reviewed migration

Upgrade builds and verifies a separate staging tree first. The predecessor seed manifest distinguishes unchanged official defaults from modified or added player files in otherwise mutable directories. Upgrade drops unchanged old defaults, merges changed and player-owned data—including AI knowledge and custom training files—without overwriting target immutable stock, then performs an atomic rename through `game.backup`. Interrupted swaps recover the last complete tree. The backup is removed only after the new tree passes complete verification. A player file whose path collides with a newly introduced immutable stock path is kept by content hash under `~/.local/share/lfs-linux/migration-conflicts/` instead of being silently discarded.

## Display policy for this workspace

All project GUI checks use Xephyr display `:111` with its Xauthority file. The nested display currently reports llvmpipe.

Xephyr proves isolated GUI behavior. It does not prove native GPU latency. Native performance claims must come from direct-host architecture or separate approved hardware measurements.
