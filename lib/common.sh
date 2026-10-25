#!/usr/bin/env bash
# Help24 - Common Bash Library
# Repository: https://github.com/help24-biz/debstrap
#
# Naming convention: object_[context_]action
#
# Supported platforms:
#   Debian 12 (Bookworm)
#   Debian 13 (Trixie)
#   Proxmox VE 9
#   Proxmox VE 8 (legacy, end of support)
#
# This library must be sourced, not executed.
# Sourcing it does not modify the system.

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

HELP24_LOG_LEVEL="${HELP24_LOG_LEVEL:-INFO}"
HELP24_LOG_FILE="${HELP24_LOG_FILE:-}"
HELP24_SCRIPT_NAME="${HELP24_SCRIPT_NAME:-${0##*/}}"

# Populated by system_detect.
HELP24_OS_ID=""
HELP24_OS_VERSION=""
HELP24_OS_CODENAME=""
HELP24_PLATFORM=""
HELP24_PVE_VERSION=""

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

log_write() {
    local level="$1"
    shift

    local timestamp message line
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    message="$*"

    line="${timestamp} [${level}] [${HELP24_SCRIPT_NAME}] ${message}"

    case "$level" in
        ERROR|FATAL|WARN)
            printf '%s\n' "$line" >&2
            ;;
        *)
            printf '%s\n' "$line"
            ;;
    esac

    if [[ -n "$HELP24_LOG_FILE" ]]; then
        printf '%s\n' "$line" >> "$HELP24_LOG_FILE" ||
            printf 'WARNING: Cannot write log file: %s\n' \
                "$HELP24_LOG_FILE" >&2
    fi
}

log_info() {
    log_write INFO "$@"
}

log_warn() {
    log_write WARN "$@"
}

log_error() {
    log_write ERROR "$@"
}

log_debug() {
    [[ "${HELP24_LOG_LEVEL^^}" == "DEBUG" ]] || return 0
    log_write DEBUG "$@"
}

log_fatal() {
    log_write FATAL "$@"
    exit 1
}

# ---------------------------------------------------------------------------
# Privilege and command checks
# ---------------------------------------------------------------------------

root_check() {
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        log_error "Root privileges are required."
        return 1
    fi

    log_debug "Root privileges verified."
    return 0
}

command_check() {
    local command_name="${1:-}"

    if [[ -z "$command_name" ]]; then
        log_error "command_check requires a command name."
        return 2
    fi

    if ! command -v "$command_name" >/dev/null 2>&1; then
        log_debug "Command not available: $command_name"
        return 1
    fi

    log_debug "Command available: $command_name"
    return 0
}

# ---------------------------------------------------------------------------
# Operating system detection
# ---------------------------------------------------------------------------

system_detect() {
    local pve_output

    HELP24_OS_ID=""
    HELP24_OS_VERSION=""
    HELP24_OS_CODENAME=""
    HELP24_PLATFORM=""
    HELP24_PVE_VERSION=""

    if [[ ! -r /etc/os-release ]]; then
        log_error "Cannot read /etc/os-release."
        return 1
    fi

    # os-release is a standard shell-compatible environment file.
    local ID="" VERSION_ID="" VERSION_CODENAME=""

    # shellcheck disable=SC1091
    source /etc/os-release

    HELP24_OS_ID="${ID:-unknown}"
    HELP24_OS_VERSION="${VERSION_ID:-unknown}"
    HELP24_OS_CODENAME="${VERSION_CODENAME:-unknown}"

    if [[ "$HELP24_OS_ID" != "debian" ]]; then
        log_error "Unsupported distribution: $HELP24_OS_ID"
        return 1
    fi

    HELP24_PLATFORM="debian"

    if command_check pveversion; then
        if ! pve_output="$(pveversion 2>/dev/null)"; then
            log_error "Proxmox detected but pveversion failed."
            return 1
        fi

        if [[ "$pve_output" =~ pve-manager/([0-9]+)\. ]]; then
            HELP24_PVE_VERSION="${BASH_REMATCH[1]}"
            HELP24_PLATFORM="proxmox"
        else
            log_error "Cannot determine Proxmox VE version."
            return 1
        fi
    fi

    case "${HELP24_PLATFORM}:${HELP24_OS_VERSION}:${HELP24_PVE_VERSION}" in
        debian:12:|debian:13:|proxmox:12:8|proxmox:13:9)
            ;;
        *)
            log_error "Unsupported platform/version combination: ${HELP24_PLATFORM}, Debian ${HELP24_OS_VERSION}, PVE ${HELP24_PVE_VERSION:-N/A}"
            return 1
            ;;
    esac

    log_info "Platform: $HELP24_PLATFORM"
    log_info "Debian: $HELP24_OS_VERSION ($HELP24_OS_CODENAME)"

    if [[ "$HELP24_PLATFORM" == "proxmox" ]]; then
        log_info "Proxmox VE: $HELP24_PVE_VERSION"
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Platform guards
# ---------------------------------------------------------------------------

platform_debian_check() {
    # Always detect the platform independently.
    # Never trust previously populated environment variables.
    if ! system_detect; then
        log_error "Platform detection failed."
        return 1
    fi

    if [[ "$HELP24_PLATFORM" != "debian" ]]; then
        log_error "Operation refused: Debian vanilla is required."
        log_error "Detected platform: ${HELP24_PLATFORM}"
        return 1
    fi

    case "$HELP24_OS_VERSION" in
        12|13)
            log_debug "Debian ${HELP24_OS_VERSION} verified."
            return 0
            ;;
        *)
            log_error "Unsupported Debian version: ${HELP24_OS_VERSION}"
            return 1
            ;;
    esac
}
