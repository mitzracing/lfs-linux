# Live for Speed Linux Launcher

Unofficial community Linux launcher for the untouched official [Live for Speed](https://www.lfs.net/) Windows build.

**Status:** v0.1.2 public source release. The validated AUR recipe awaits maintainer SSH access. The core works without Steam, Bottles, Lutris, or a background launcher.

This project is not affiliated with or endorsed by the Live for Speed developers.

Project website: <https://mitzracing.github.io/live-for-speed-linux-launcher/>

The public package is `live-for-speed-launcher`. The stable command and player-state paths keep the `lfs-linux` name for compatibility.

## What it does

- Downloads LFS directly from `lfs.net` after an explicit user command.
- Verifies the official archive, extracts it without executing the installer, and checks every immutable stock file.
- Creates one private Wine prefix and uses only audited Wine 11.15-1 under the XDG data directory.
- Deploys only DXVK's 32-bit D3D9 DLL for the stock game.
- Starts Wine directly with no wrapper daemon or container.
- Preserves game-owned settings, profiles, replays, unlock state, and cache.
- Detects official download-page changes without editing game files.

## What it does not do

- Redistribute LFS binaries or proprietary assets
- Patch `LFS.exe`, cars, tracks, shaders, textures, or configuration
- Store account credentials
- Unlock licensed content
- Update game or runtime files during launch
- Claim official LFS support for Linux

## One-click setup

After installing the wrapper package, open **Live for Speed Linux Launcher** from the application menu. First launch shows one informed confirmation, verifies the official LFS, Wine, and DXVK inputs, configures the private prefix, and starts LFS. Later launches go directly to the game.

No game payload is bundled with the wrapper package.

## Commands

```text
lfs-linux setup         Interactive first-run setup used by the desktop launcher
lfs-linux install       Install or repair verified upstream runtime files
lfs-linux launch        Validate pins and start LFS
lfs-linux stop          Stop only this private Wine prefix
lfs-linux doctor        Check host and installation state
lfs-linux status        Show versions and paths
lfs-linux update-check  Compare pins with the official downloads page
lfs-linux verify-sources  Fully download and verify pinned release inputs
lfs-linux purge-cache   Remove wrapper download and shader caches
lfs-linux remove        Remove per-user prefix after explicit confirmation
```

## Requirements

- Linux x86_64
- Audited Wine 11.15-1 (the wrapper provisions the pinned Arch runtime when that exact system package is unavailable)
- Vulkan-capable GPU and driver
- Bash, 7-Zip, curl, GNU core utilities, findutils, libarchive (`bsdtar`), tar, and util-linux
- A supported terminal for graphical first-run setup (`xterm` is the AUR default)

The audited Arch Wine runtime uses pure WoW64. This lets its x86_64 package run the 32-bit LFS executable without the traditional 32-bit Unix Wine stack. Other Wine versions fail closed instead of being accepted by a broad compatibility range.

## Install from source

```bash
make test
sudo make install
lfs-linux install
lfs-linux launch
```

System installation needs root because it writes under `/usr`. Game installation is user-local and must not use root.

## Arch and Manjaro

A publish-ready package recipe is in [`packaging/aur/`](packaging/aur/README.md). After publication, Pamac users can find `live-for-speed-launcher` when AUR support is enabled.

The AUR package contains only this open-source wrapper. It does not contain the game installer or game files.

## Other distributions

The core uses standard shell tools and a native Wine runtime. Distribution packages install files from `Makefile`; they must provide exact Wine 11.15-1 or allow the wrapper to provision the pinned archived package privately.

The full package name avoids confusion with Linux From Scratch. Existing scripts can continue to use the `lfs-linux` command.

## Separate launcher, small patches

This project is not a fork. Most upstream updates change one audited manifest and then run the existing clean-install checks.

Contributors do not need game source, a private build server, or a full-time service. See [`docs/MAINTENANCE.md`](docs/MAINTENANCE.md).

## Low-overhead architecture

```text
lfs-linux -> audited Wine 11.15-1 -> stock LFS.exe -> private DXVK d3d9 -> host Vulkan driver
```

No Bottles process, Steam client, Gamescope session, web UI, or update request exists in the hot path. Shader cache persists between launches.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for state paths and performance boundaries.

## Updates

Run:

```bash
lfs-linux update-check
```

A changed official release returns a review-required status. It does not modify LFS.

Maintainers update all release pins together after a clean install and live run. See [`docs/RELEASING.md`](docs/RELEASING.md).

## Flathub

Current Flathub policy accepts Wine-based Windows applications only as official upstream submissions. This project will not submit an unauthorized manifest.

[`docs/FLATHUB.md`](docs/FLATHUB.md) defines the authorization gate and proposal path.

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md), [`docs/LEGAL.md`](docs/LEGAL.md), and [`SECURITY.md`](SECURITY.md).

Never attach passwords, unlock codes, Wine registry files, or proprietary game assets to an issue.

## License

Wrapper code: MIT.

Live for Speed: proprietary, governed by its own [terms](https://www.lfs.net/agreement).

DXVK: Zlib license, downloaded from its official release page.
