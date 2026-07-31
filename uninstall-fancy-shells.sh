#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

MARKER='fancy-shells'
HOME_MARKER="${HOME}/.fancy-shells-home"
VERSION_MARKER="${HOME}/.fancy-shells-version"

if [ -z "${BASH_VERSION:-}" ]; then
    echo "This uninstaller must be run from Bash." >&2
    exit 1
fi

log() {
    if command -v logger >/dev/null 2>&1; then
        logger -t fancy-shells "$*"
    fi
    echo "$*" >&2
}

BASHRC="$HOME/.bashrc"
BACKUP="$HOME/.bashrc.original"
did_something=0

if [ -f "$BACKUP" ]; then
    cp "$BACKUP" "$BASHRC"
    rm -f "$BACKUP"
    log "Restored $BASHRC from backup and removed $BACKUP."
    did_something=1
elif [ -f "$BASHRC" ] && grep -qF "$MARKER" "$BASHRC"; then
    rm -f "$BASHRC"
    log "Removed fancy-shells $BASHRC (no prior backup)."
    did_something=1
fi

if [ -f "$HOME_MARKER" ]; then
    rm -f "$HOME_MARKER"
    log "Removed $HOME_MARKER"
    did_something=1
fi

if [ -f "$VERSION_MARKER" ]; then
    rm -f "$VERSION_MARKER"
    log "Removed $VERSION_MARKER"
    did_something=1
fi

if [ "$did_something" -eq 0 ]; then
    log "Nothing to uninstall for Bash."
    exit 0
fi

echo "Bash config restored. Run 'exec bash' or start a new shell to apply."
