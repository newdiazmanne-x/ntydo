#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="${NYDO_SECRETS_DIR:-$HOME/.secrets}"
SCRIPT_REL="scripts/security-check.sh"

get_octal_mode() {
  local target="$1"
  if stat -c '%a' "$target" 2>/dev/null; then
    return 0
  fi
  if stat -f '%Lp' "$target" 2>/dev/null; then
    return 0
  fi
  return 1
}

echo "[1/2] Checking permissions on $SECRETS_DIR..."
if [ -d "$SECRETS_DIR" ]; then
  dir_mode="$(get_octal_mode "$SECRETS_DIR" || true)"
  if [ -n "$dir_mode" ] && [ "$dir_mode" != "700" ]; then
    echo "[-] $SECRETS_DIR has mode $dir_mode (expected 700). Run: chmod 700 \"$SECRETS_DIR\"" >&2
    exit 1
  fi

  bad_files=0
  while IFS= read -r -d '' secret_file; do
    file_mode="$(get_octal_mode "$secret_file" || true)"
    if [ -n "$file_mode" ] && [ "$file_mode" != "600" ]; then
      echo "[-] Secret file '$secret_file' has mode $file_mode (expected 600). Run: chmod 600 \"$secret_file\"" >&2
      bad_files=$((bad_files + 1))
    fi
  done < <(find "$SECRETS_DIR" -maxdepth 2 -type f -print0 2>/dev/null || true)

  if [ "$bad_files" -gt 0 ]; then
    exit 1
  fi
  echo "[+] $SECRETS_DIR permissions verified."
else
  echo "[!] $SECRETS_DIR does not exist yet. Create with: mkdir -p ~/.secrets && chmod 700 ~/.secrets"
fi

echo "[2/2] Scanning $REPO_ROOT for common secret patterns..."
PATTERN='(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|tskey-auth-[A-Za-z0-9_-]{10,}|AIza[0-9A-Za-z_-]{20,}|sk-[A-Za-z0-9_-]{20,}|-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----)'

matches=0
while IFS= read -r -d '' file_path; do
  rel_path="${file_path#"$REPO_ROOT"/}"
  case "$rel_path" in
    .git/*|*/.git/*|.venv/*|*/.venv/*|"$SCRIPT_REL")
      continue
      ;;
  esac
  if grep -nE "$PATTERN" "$file_path" >/dev/null 2>&1; then
    echo "[-] Potential secret pattern matched in: $rel_path" >&2
    grep -nE "$PATTERN" "$file_path" >&2 || true
    matches=$((matches + 1))
  fi
done < <(find "$REPO_ROOT" -type f -not -path '*/.git/*' -not -path '*/.venv/*' -print0)

if [ "$matches" -gt 0 ]; then
  echo "[-] Security scan failed with $matches matching file(s)." >&2
  exit 1
fi

echo "[+] Repository secret scan clean."
