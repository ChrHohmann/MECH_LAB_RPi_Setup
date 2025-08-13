#!/usr/bin/env bash
set -euo pipefail

# Repo-Root ermitteln
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC_DIR="$REPO_ROOT/etc/update-motd.d"
DST_DIR="/etc/update-motd.d"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "[MOTD] Quelle $SRC_DIR nicht gefunden" >&2
  exit 1
fi

mkdir -p "$DST_DIR"
# Dateien kopieren und ausführbar setzen
install -m 755 "$SRC_DIR/20-debian" "$DST_DIR/20-debian"
install -m 755 "$SRC_DIR/30-hslu"   "$DST_DIR/30-hslu"

echo "[MOTD] PAM-sshd: statische MOTD deaktivieren"
sed -i '/session    optional     pam_motd.so noupdate/c\# session    optional     pam_motd.so noupdate' \
  /etc/pam.d/sshd

echo "[OK] MOTD eingerichtet"