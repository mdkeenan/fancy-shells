# Fancy Shells

Install a custom prompt, shell defaults, and a set of `fs*` CLI tools for Bash or PowerShell.

**Current version:** see [`VERSION`](VERSION) (semver).

![Fancy shells prompt on Linux](assets/fancy-shells-1024x320.png)
*Example of the custom prompt on Linux and Windows.*

## Features

### Custom prompt

Both shells use the same layout and color scheme:

```
[time:user:privilege:hostname:dir]$
```

| Segment | Color | Example |
|---------|-------|---------|
| Brackets, colons, `$` | Yellow | `[` `:` `]` `$` |
| Time | Default | `02:45:53` |
| Username | Green | `csagan` |
| Privilege | Red or dim gray | `admuser` / `stduser` |
| Hostname | Cyan | `ubuntu` |
| Directory | Blue | `~/One/Doc` |

- **Privilege** — `admuser` (red) when running as root or a member of the sudo/wheel/admin group; `stduser` (dim gray) otherwise. On Windows, membership in the Administrators group counts as `admuser`.
- **Directory** — paths under home display with a Linux-style tilde (`~`, `~/Documents`). Each folder name is shortened to its first three characters (`~/OneDrive/Documents` → `~/One/Doc`).
- **Suffix** — all prompts end with `$` (privilege is shown in the `admuser`/`stduser` segment, not with `#`).
- **Window title** — PowerShell always sets the title to the full path; Bash sets it for `xterm*` / `rxvt*` terminals.

### Shell defaults

- **History** — large command history with duplicate suppression (Bash: 50,000 entries; PowerShell: 32,767).
- **Directory helpers** — `ll`, `la`, and `l` aliases/functions (Bash: `ls` variants; PowerShell: `Get-ChildItem` variants).
- **User aliases** — optional `~/.bash_aliases` or `~/.powershell_aliases.ps1` loaded automatically if present.
- **Bash extras** — colored `ls`/`grep`, bash-completion, and cross-session history sync.

### CLI tools (`fs*`)

Install also creates a Python venv under `tools/venv` and puts `tools/bin` on your `PATH` via `~/.fancy-shells-home`. Commands:

| Tool | Description |
|------|-------------|
| `fssift` | Search/filter lines in a file by pattern (mini-grep) |
| `fsjott` | Quick command-line notes/journal |
| `fspw` | Random password/passphrase generator |
| `fssysinfo` | Snapshot of CPU, memory, disk, and network info |
| `fsrenamer` | Batch-rename files in a folder |
| `fsgclean` | Delete local git branches already merged into main/master |
| `fsgstat` | Quick git repo summary |
| `fsgwip` | Stage and commit all changes as a WIP checkpoint |
| `fstodo` | Task list with pending/done status |
| `fsdirsize` | Show the largest files/subfolders under a directory |
| `fsenvcheck` | Check that required CLI tools and env vars are present |
| `fsjsonfmt` | Pretty-print, validate, and query JSON files |
| `fsbackup` | Zip a folder with a timestamp for a quick snapshot |

See [TOOLS.md](TOOLS.md) for flags and examples.

### Install safety

- Backs up your existing config to `~/.bashrc.original` or `$PROFILE.original` before replacing it (once), and **only** if the current file is not already fancy-shells (so upgrades never promote a fancy config to “original”).
- **Replaces the entire** `~/.bashrc` / `$PROFILE` with the fancy-shells config (it does not merge). Re-running install refreshes the fancy config but keeps the original backup.
- Copies config from a validated local checkout (marker check) rather than writing an empty download.
- PowerShell installer reloads the profile automatically after install.
- Uninstall restores the backup when available and removes `~/.fancy-shells-home` and `~/.fancy-shells-version`. The tools checkout/venv is left in place.

### Versioning and upgrades

- Package version lives in [`VERSION`](VERSION) and in the first line of `bashrc` / `profile.ps1` (`fancy-shells version: X.Y.Z`).
- Install writes `~/.fancy-shells-version` and prefers an existing `~/.fancy-shells-home` checkout on upgrade (so a prior local install is updated in place).
- Re-running the installer is safe: same version reinstalls; older → newer upgrades; newer → older prints a downgrade warning but still proceeds.
- Pre-version installs (prompt-only fancy-shells with no version marker) are treated as `1.0.0` and upgrade cleanly to the current release (adds tools PATH + venv).

When cutting a release, bump the same semver in `VERSION`, and in the first-line comments of `bashrc` and `profile.ps1`.

## Requirements

- **Bash install:** Bash, `git`, Python 3, `curl` (for the one-liner)
- **PowerShell install:** Windows PowerShell 5.1+ or PowerShell 7+, `git` (for remote clone), Python 3
- **PowerShell one-liner:** may require an ExecutionPolicy that allows scripts (e.g. `RemoteSigned` for local profiles)

## Bash

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mdkeenan/fancy-shells/main/install-fancy-shells.sh)
```

From a local clone:

```bash
./install-fancy-shells.sh
```

Then run `exec bash` or `source ~/.bashrc` if the prompt does not update immediately.

Install root resolution: local checkout (if the script is run from this repo) → existing `~/.fancy-shells-home` → clone/update `~/fancy-shells`.

## PowerShell

```powershell
irm https://raw.githubusercontent.com/mdkeenan/fancy-shells/main/install-fancy-shells.ps1 | iex
```

From a local clone:

```powershell
.\install-fancy-shells.ps1
```

Works with Windows PowerShell 5.1 and PowerShell 7+ (`pwsh`). Same install-root resolution as Bash (`$HOME\fancy-shells` when cloning). Each host uses its own `$PROFILE` path (Windows PowerShell vs PowerShell 7).

## Uninstall

**Bash:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mdkeenan/fancy-shells/main/uninstall-fancy-shells.sh)
```

**PowerShell:**

```powershell
irm https://raw.githubusercontent.com/mdkeenan/fancy-shells/main/uninstall-fancy-shells.ps1 | iex
```

From a local clone, run `./uninstall-fancy-shells.sh` or `.\uninstall-fancy-shells.ps1`.

If a backup exists, the original config is restored. Otherwise the fancy-shells config is removed. `~/.fancy-shells-home` and `~/.fancy-shells-version` are removed so `fs*` leaves `PATH`; the repo/venv is not deleted.

## Examples

```text
[02:45:53:csagan:admuser:ASUS-LT:~/One/Doc]$
[02:35:14:csagan:admuser:ubuntu:~/tes]$
[22:07:05:fdrake:stduser:ubuntu:~]$
```
