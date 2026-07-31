#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

REPO_URL='https://github.com/mdkeenan/fancy-shells.git'
MARKER='fancy-shells'
HOME_MARKER="${HOME}/.fancy-shells-home"
VERSION_MARKER="${HOME}/.fancy-shells-version"
LEGACY_VERSION='1.0.0'

if [ -z "${BASH_VERSION:-}" ]; then
    echo "This installer must be run from Bash." >&2
    exit 1
fi

is_fancy_shells_repo() {
    local path="$1"
    [ -n "$path" ] && [ -d "${path}/tools" ] && [ -f "${path}/VERSION" ] && { [ -f "${path}/bashrc" ] || [ -f "${path}/profile.ps1" ]; }
}

read_version_file() {
    local path="$1"
    if [ ! -f "$path" ]; then
        return 1
    fi
    local raw
    raw="$(tr -d '\r\n' <"$path" | tr -d '\357\273\277')"
    if [[ "$raw" =~ ^([0-9]+\.[0-9]+\.[0-9]+) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

get_installed_version() {
    local from_marker from_bashrc
    if from_marker="$(read_version_file "$VERSION_MARKER")"; then
        printf '%s' "$from_marker"
        return 0
    fi
    if [ -f "$HOME/.bashrc" ]; then
        from_bashrc="$(grep -Eo 'fancy-shells version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+' "$HOME/.bashrc" 2>/dev/null | head -n1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' || true)"
        if [ -n "$from_bashrc" ]; then
            printf '%s' "$from_bashrc"
            return 0
        fi
        if grep -qF "$MARKER" "$HOME/.bashrc"; then
            printf '%s' "$LEGACY_VERSION"
            return 0
        fi
    fi
    return 1
}

compare_semver() {
    local left="$1" right="$2"
    local IFS=.
    # shellcheck disable=SC2206
    local l=($left) r=($right)
    local i
    for i in 0 1 2; do
        if ((10#${l[i]} < 10#${r[i]})); then
            echo -1
            return
        fi
        if ((10#${l[i]} > 10#${r[i]})); then
            echo 1
            return
        fi
    done
    echo 0
}

update_checkout() {
    local path="$1"
    if command -v git >/dev/null 2>&1 && [ -d "${path}/.git" ]; then
        git -C "$path" pull --ff-only >/dev/null 2>&1 || true
    fi
}

resolve_fancy_shells_home() {
    local script_dir existing default
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if is_fancy_shells_repo "$script_dir"; then
        printf '%s' "$script_dir"
        return
    fi

    if [ -f "$HOME_MARKER" ]; then
        existing="$(tr -d '\r\n' <"$HOME_MARKER" | tr -d '\357\273\277')"
        if is_fancy_shells_repo "$existing"; then
            update_checkout "$existing"
            printf '%s' "$existing"
            return
        fi
    fi

    default="${HOME}/fancy-shells"
    if is_fancy_shells_repo "$default"; then
        update_checkout "$default"
        printf '%s' "$default"
        return
    fi

    if [ -d "${default}/.git" ]; then
        update_checkout "$default"
        if is_fancy_shells_repo "$default"; then
            printf '%s' "$default"
            return
        fi
    fi

    if [ -e "$default" ]; then
        echo "Path $default exists but is not a fancy-shells checkout with tools/ and VERSION." >&2
        exit 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo "git is required on PATH to clone fancy-shells." >&2
        exit 1
    fi

    git clone "$REPO_URL" "$default"
    if ! is_fancy_shells_repo "$default"; then
        echo "Cloned $default but it is missing tools/ or VERSION. Push a complete release first." >&2
        exit 1
    fi
    printf '%s' "$default"
}

install_tools_venv() {
    local root="$1"
    local venv_dir="${root}/tools/venv"
    local requirements="${root}/tools/requirements.txt"
    local python_bin=""

    if [ ! -f "$requirements" ]; then
        echo "Missing tools requirements at $requirements" >&2
        exit 1
    fi

    if command -v python3 >/dev/null 2>&1; then
        python_bin=python3
    elif command -v python >/dev/null 2>&1; then
        python_bin=python
    else
        echo "Python 3 is required on PATH to install fancy-shells tools." >&2
        exit 1
    fi

    if [ ! -x "${venv_dir}/bin/python" ]; then
        echo "Creating tools virtual environment..."
        "$python_bin" -m venv "$venv_dir"
    fi

    echo "Installing tool dependencies..."
    "${venv_dir}/bin/python" -m pip install -q -r "$requirements"
}

install_bashrc_from_clone() {
    local root="$1"
    local src="${root}/bashrc"
    local bashrc="${HOME}/.bashrc"
    local backup="${HOME}/.bashrc.original"
    local temp

    if [ ! -f "$src" ]; then
        echo "Missing bashrc in $root" >&2
        exit 1
    fi

    if [ ! -s "$src" ] || ! grep -qF "$MARKER" "$src"; then
        echo "bashrc failed validation (empty or missing fancy-shells marker); aborting." >&2
        exit 1
    fi

    # Never treat an existing fancy-shells bashrc as the pre-install backup.
    if [ -f "$bashrc" ] && [ ! -f "$backup" ]; then
        if grep -qF "$MARKER" "$bashrc"; then
            echo "Skipping backup: current .bashrc is already fancy-shells and no $backup exists." >&2
        else
            cp "$bashrc" "$backup"
            echo "Backed up existing .bashrc to $backup"
        fi
    fi

    temp="$(mktemp)"
    # shellcheck disable=SC2064
    trap 'rm -f "$temp"' RETURN
    cp "$src" "$temp"
    if [ ! -s "$temp" ] || ! grep -qF "$MARKER" "$temp"; then
        echo "Temp bashrc validation failed; aborting install." >&2
        exit 1
    fi
    cp "$temp" "$bashrc"
}

PREVIOUS_VERSION=""
if PREVIOUS_VERSION="$(get_installed_version)"; then
    :
else
    PREVIOUS_VERSION=""
fi

ROOT="$(resolve_fancy_shells_home)"
TARGET_VERSION="$(read_version_file "${ROOT}/VERSION")" || {
    echo "Missing or invalid VERSION in $ROOT" >&2
    exit 1
}

if [ -n "$PREVIOUS_VERSION" ]; then
    cmp="$(compare_semver "$PREVIOUS_VERSION" "$TARGET_VERSION")"
    if [ "$cmp" -eq 0 ]; then
        echo "Reinstalling fancy-shells $TARGET_VERSION (same version)..."
    elif [ "$cmp" -lt 0 ]; then
        echo "Upgrading fancy-shells $PREVIOUS_VERSION -> $TARGET_VERSION..."
    else
        echo "Installing fancy-shells $TARGET_VERSION over newer installed $PREVIOUS_VERSION (downgrade)..." >&2
    fi
else
    echo "Installing fancy-shells $TARGET_VERSION..."
fi

printf '%s\n' "$ROOT" >"$HOME_MARKER"
printf '%s\n' "$TARGET_VERSION" >"$VERSION_MARKER"

install_tools_venv "$ROOT"
install_bashrc_from_clone "$ROOT"

echo "Fancy shells $TARGET_VERSION installed from $ROOT"
echo "Wrote $HOME_MARKER"
echo "Wrote $VERSION_MARKER"
echo "New .bashrc installed. Run 'exec bash' or 'source ~/.bashrc' to apply."
echo "fs* tools will be on PATH after reloading the shell."
