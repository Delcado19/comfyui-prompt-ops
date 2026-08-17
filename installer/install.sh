#!/usr/bin/env bash
# ComfyUI Prompt Ops Installer (Linux)
# installer/install.sh
#
# Equivalent to installer/install.ps1: installs Espanso + CopyQ, deploys the
# snippets, regenerates snippet docs, and (re)starts the background apps.
# No root/sudo elevation of the whole script: package install needs sudo,
# everything else (snippets, docs, starting apps) is per-user, same as
# Windows where nothing below needs admin either.

set -u

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
log_dir="$repo_root/logs"
log_file="$log_dir/install.log"
mkdir -p "$log_dir"

log() {
    # level msg
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" >> "$log_file"
}

info() { printf '\033[36m[INFO]\033[0m %s\n' "$1"; log "INFO" "$1"; }
warn() { printf '\033[33m[WARN]\033[0m %s\n' "$1"; log "WARN" "$1"; }
ok()   { printf '\033[32m[ OK ]\033[0m %s\n' "$1"; log "OK" "$1"; }
err()  { printf '\033[31m[FAIL]\033[0m %s\n' "$1"; log "FAIL" "$1"; }

fail() {
    err "$1"
    err "See $log_file for the full log."
    exit 1
}

sudo_if_needed() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

detect_pkg_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v zypper >/dev/null 2>&1; then
        echo "zypper"
    else
        echo ""
    fi
}

install_pkg() {
    # install_pkg <human name> <package name>
    name="$1"
    pkg="$2"

    case "$pkg_manager" in
        apt)    sudo_if_needed apt-get update -y && sudo_if_needed apt-get install -y "$pkg" ;;
        dnf)    sudo_if_needed dnf install -y "$pkg" ;;
        pacman) sudo_if_needed pacman -Sy --noconfirm "$pkg" ;;
        zypper) sudo_if_needed zypper install -y "$pkg" ;;
        *)      return 1 ;;
    esac
}

ensure_command() {
    # ensure_command <command> <human name> <package name> <manual install url>
    cmd="$1"; name="$2"; pkg="$3"; url="$4"

    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$name detected"
        return 0
    fi

    warn "$name not found"

    if [ -z "$pkg_manager" ]; then
        warn "No supported package manager found. Install $name manually: $url"
        return 1
    fi

    info "Installing $name via $pkg_manager..."

    if install_pkg "$name" "$pkg"; then
        ok "$name installed"
        return 0
    fi

    warn "$pkg_manager could not install $name. Install it manually: $url"
    return 1
}

echo ""
echo "====================================="
echo " ComfyUI Prompt Ops Installer (Linux)"
echo "====================================="
echo ""

pkg_manager="$(detect_pkg_manager)"

if [ -n "$pkg_manager" ]; then
    ok "Package manager detected: $pkg_manager"
else
    warn "No known package manager (apt/dnf/pacman/zypper) found."
fi

# --------------------------------------------------
# PowerShell 7 (pwsh) - shared with the snippet install/doc-gen scripts
# --------------------------------------------------

info "Checking PowerShell 7 (pwsh)..."

if ! ensure_command "pwsh" "PowerShell 7" "powershell" "https://aka.ms/pwsh"; then
    fail "PowerShell 7 (pwsh) is required to run scripts/install_snippets.ps1 and scripts/generate_snippet_docs.ps1."
fi

# --------------------------------------------------
# Espanso
# --------------------------------------------------

info "Checking Espanso..."
ensure_command "espanso" "Espanso" "espanso" "https://espanso.org/install"

# --------------------------------------------------
# CopyQ
# --------------------------------------------------

info "Checking CopyQ..."
ensure_command "copyq" "CopyQ" "copyq" "https://copyq.readthedocs.io/en/latest/installation.html"

# --------------------------------------------------
# Install Snippets
# --------------------------------------------------

info "Installing snippets..."

if ! pwsh -NoProfile -File "$repo_root/scripts/install_snippets.ps1"; then
    fail "install_snippets.ps1 failed"
fi

ok "Snippets installed"

# --------------------------------------------------
# Generate Docs
# --------------------------------------------------

info "Generating snippet documentation..."

if ! pwsh -NoProfile -File "$repo_root/scripts/generate_snippet_docs.ps1"; then
    fail "generate_snippet_docs.ps1 failed"
fi

ok "Snippet docs generated"

# --------------------------------------------------
# Restart Services
# --------------------------------------------------

info "Restarting services..."

if ! pwsh -NoProfile -File "$repo_root/scripts/restart_services.ps1"; then
    fail "restart_services.ps1 failed"
fi

ok "Services restarted"

echo ""
ok "Setup completed"
echo ""
