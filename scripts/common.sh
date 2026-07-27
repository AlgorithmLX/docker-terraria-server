#!/usr/bin/env bash

set -Eeuo pipefail

log() {
  printf '[terraria] %s\n' "$*"
}

warn() {
  printf '[terraria][warn] %s\n' "$*" >&2
}

die() {
  printf '[terraria][error] %s\n' "$*" >&2
  exit 1
}

upper() {
  printf '%s' "${1:-}" | tr '[:lower:]' '[:upper:]'
}

lower() {
  printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]'
}

trim() {
  local value="${1:-}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

truthy() {
  case "$(upper "${1:-}")" in
    1|TRUE|T|YES|Y|ON) return 0 ;;
    *) return 1 ;;
  esac
}

normalize_type() {
  case "$(upper "${1:-VANILLA}")" in
    VANILLA|TERRARIA) printf 'VANILLA' ;;
    TML|TMODLOADER|MODDED) printf 'TML' ;;
    *) die "Unsupported TYPE='${1:-}'. Use VANILLA or TML." ;;
  esac
}

download() {
  local url="$1"
  local dest="$2"
  local force="${3:-FALSE}"

  if [[ -f "$dest" ]] && ! truthy "$force"; then
    log "Using cached $(basename "$dest")"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  log "Downloading $url"
  curl -fsSL --retry 5 --retry-delay 3 --connect-timeout 20 -o "$dest" "$url"
}

sha256_verify() {
  local file="$1"
  local expected="${2:-}"

  [[ -z "$expected" ]] && return 0

  local actual
  actual="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || die "Checksum mismatch for $file: expected $expected, got $actual"
}

version_digits() {
  printf '%s' "$1" | tr -cd '0-9'
}

is_url() {
  [[ "${1:-}" =~ ^https?:// ]]
}

safe_basename_from_url() {
  local url="$1"
  local without_query="${url%%\?*}"
  basename "$without_query"
}

split_values() {
  local raw="${1:-}"
  printf '%s\n' "$raw" | tr ',;' '\n' | while IFS= read -r item; do
    item="$(trim "$item")"
    [[ -z "$item" ]] && continue
    printf '%s\n' "$item"
  done
}

normalize_world_size() {
  case "$(lower "${1:-2}")" in
    small|1) printf '1' ;;
    medium|normal|2) printf '2' ;;
    large|3) printf '3' ;;
    none|off|0) printf '0' ;;
    *) die "Invalid AUTOCREATE='${1:-}'. Use 1/small, 2/medium, 3/large, or 0/off." ;;
  esac
}

normalize_difficulty() {
  case "$(lower "${1:-0}")" in
    classic|normal|0) printf '0' ;;
    expert|1) printf '1' ;;
    master|2) printf '2' ;;
    journey|3) printf '3' ;;
    *) die "Invalid DIFFICULTY='${1:-}'. Use 0/classic, 1/expert, 2/master, or 3/journey." ;;
  esac
}
