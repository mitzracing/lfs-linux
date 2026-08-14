# Troubleshooting

## Start with diagnostics

```bash
lfs-linux doctor
lfs-linux status
```

Read the newest launch log:

```bash
less ~/.local/state/lfs-linux/latest.log
```

## Stop a stuck game

Try the in-game command:

```text
/exit
```

Then run:

```bash
lfs-linux stop
```

The command targets only processes with this wrapper's private `WINEPREFIX`.

## Vulkan or DXVK failure

Run:

```bash
vulkaninfo --summary
lfs-linux doctor
```

Install a current Vulkan driver for the GPU. On Arch, select the matching `vulkan-driver` provider.

The wrapper verifies both its private DXVK DLL and the prefix copy. Run `lfs-linux install` to repair a failed DXVK check.

## Missing audio

Open the system audio mixer while LFS runs. Confirm that an `LFS.exe` stream exists and is not muted.

Press `W` in LFS to initialize sound again. Press `N` only to switch sound on or off.

Install the Wine audio dependencies recommended by the distribution when no stream appears.

## Full-screen recovery

Press `Shift+F4` to return to windowed mode.

Every wrapper launch passes `/windowed=yes`. This gives a recoverable default without editing `cfg.txt`.

## Setup reports an incomplete stock tree

The wrapper does not execute the NSIS installer under Wine. It extracts the verified official archive with 7-Zip and verifies every immutable stock file against the shipped 0.7G manifest. Player-owned settings, setups, layouts, replays, and similar paths are excluded from that immutable inventory and preserved during repair. If any stock file is absent or changed, diagnostics fail and `lfs-linux install` restores it from the verified archive before writing a new marker.

## Upstream update detected

Run:

```bash
lfs-linux update-check
```

A review-required result is not an installation failure. It means maintainers must verify and release new pins.

Do not bypass checksum checks. Do not patch `LFS.exe`.

## Wine runtime problem

Wrapper 0.1.0 accepts only the complete audited Arch Wine 11.15-1 payload. It uses that exact system package or provisions the pinned archive privately. Back up the state directory before manual recovery:

```bash
cp -a ~/.local/share/lfs-linux ~/lfs-linux-backup
```

Run `lfs-linux install` to reprovision a missing or changed private runtime, then run `lfs-linux doctor`. A different Wine version is rejected; maintainers must publish new archive and runtime-manifest pins after compatibility testing. Do not delete the prefix unless the backup is complete.

## Remove cache without removing player data

```bash
lfs-linux purge-cache
```

This command keeps the Wine prefix, profiles, settings, replays, and unlock state.

## Remove everything

```bash
lfs-linux remove
```

The command asks for confirmation because it removes game-owned player data in the private prefix. Package removal alone preserves this data.

## Controller and force feedback

Connect the controller before launch. Configure it in **Options > Controls**.

Input can work when force feedback does not. Force feedback depends on the wheel and Linux kernel driver.

Do not report controller support without the device model, kernel version, and a real input test.
