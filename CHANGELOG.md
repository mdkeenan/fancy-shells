# Changelog

All notable changes to fancy-shells are documented here. Version numbers match [`VERSION`](VERSION).

## 2.0.0

- Install prompt config and `fs*` CLI tools together (Python venv under `tools/`, wrappers in `tools/bin`).
- Track installs with `~/.fancy-shells-home` and `~/.fancy-shells-version` (semver).
- Upgrade-safe reinstall: prefer existing home checkout, treat pre-version installs as `1.0.0`, never back up an existing fancy config as `*.original`.
- Add uninstall scripts; remove home/version markers on uninstall.
- Align Bash prompt time with PowerShell (`HH:MM:SS`).
- Document tools in [TOOLS.md](TOOLS.md).

## 1.0.0

- Initial prompt-only fancy-shells install for Bash and PowerShell (pre-version marker era).
