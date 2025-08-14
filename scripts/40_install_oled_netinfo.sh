#!/usr/bin/env bash
set -euo pipefail

# --- Konfiguration ---
REPO_URL=${REPO_URL:-"https://github.com/ChrHohmann/oled_netinfo.git"}
TARGET_DIR=${TARGET_DIR:-"/opt/oled_netinfo"}
RUN_USER=${RUN_USER:-"pi"}                 # Dienst läuft unter 'pi'
PYTHON_BIN=${PYTHON_BIN:-python3}
LOCAL_VENV_DIR=${LOCAL_VENV_DIR:-"$TARGET_DIR/venv"}  # Eigene, unabhängige venv

SYSTEMD_DIR="/etc/systemd/system"

echo "[oled_netinfo] Repo:       $REPO_URL"
echo "[oled_netinfo] Ziel:       $TARGET_DIR (User: $RUN_USER)"
echo "[oled_netinfo] Lokale venv: $LOCAL_VENV_DIR"

# 1) Repository holen/aktualisieren
if [[ -d "$TARGET_DIR/.git" ]]; then
  echo "[oled_netinfo] Aktualisiere bestehendes Repo..."
  git -C "$TARGET_DIR" fetch --all --quiet || true
  git -C "$TARGET_DIR" pull --ff-only || true
else
  echo "[oled_netinfo] Klone Repository..."
  git clone "$REPO_URL" "$TARGET_DIR"
fi

# Besitz setzen
chown -R "$RUN_USER:$RUN_USER" "$TARGET_DIR" || true

# 2) Eigene venv im Repo-Unterverzeichnis anlegen (unabhängig von globaler venv)
if [[ ! -x "$LOCAL_VENV_DIR/bin/python" ]]; then
  echo "[oled_netinfo] Erstelle lokale venv unter $LOCAL_VENV_DIR"
  sudo -u "$RUN_USER" "$PYTHON_BIN" -m venv "$LOCAL_VENV_DIR"
fi

# 3) Abhängigkeiten in die lokale venv installieren
"$LOCAL_VENV_DIR/bin/pip" install --upgrade pip wheel setuptools
if [[ -f "$TARGET_DIR/requirements.txt" ]]; then
  echo "[oled_netinfo] Installiere Requirements in lokale venv"
  "$LOCAL_VENV_DIR/bin/pip" install -r "$TARGET_DIR/requirements.txt"
else
  echo "[oled_netinfo] Keine requirements.txt gefunden – überspringe PIP-Install."
fi

# 4) Systemd-Units aus dem Repo installieren (Service + Timer)
#    Erwartete Pfade:  ./systemd/*.service  ./systemd/*.timer (rekursiv gesucht)
mapfile -t UNIT_FILES < <(find "$TARGET_DIR" -type f \( -name "*.service" -o -name "*.timer" \))
if (( ${#UNIT_FILES[@]} == 0 )); then
  echo "[oled_netinfo] Keine *.service/*.timer im Repo gefunden – überspringe Systemd-Setup."
  exit 0
fi

for uf in "${UNIT_FILES[@]}"; do
  base=$(basename "$uf")
  echo "[oled_netinfo] Installiere Unit: $base"
  install -m 644 "$uf" "$SYSTEMD_DIR/$base"

  # Platzhalter in den Unit-Files ersetzen, falls vorhanden
  if grep -q "@USER@" "$SYSTEMD_DIR/$base"; then
    sed -i "s/@USER@/$RUN_USER/g" "$SYSTEMD_DIR/$base"
  fi
  if grep -q "@VENV_DIR@" "$SYSTEMD_DIR/$base"; then
    sed -i "s|@VENV_DIR@|$LOCAL_VENV_DIR|g" "$SYSTEMD_DIR/$base"
  fi
  if grep -q "@APP_DIR@" "$SYSTEMD_DIR/$base"; then
    sed -i "s|@APP_DIR@|$TARGET_DIR|g" "$SYSTEMD_DIR/$base"
  fi

done

# 5) Daemon neu laden und Services/Timer aktivieren
systemctl daemon-reload
for uf in "${UNIT_FILES[@]}"; do
  base=$(basename "$uf")
  if [[ "$base" == *.timer ]]; then
    echo "[oled_netinfo] Aktiviere Timer: $base"
    systemctl enable --now "$base"
  elif [[ "$base" == *.service ]]; then
    echo "[oled_netinfo] Aktiviere Service: $base"
    systemctl enable --now "$base"
  fi
done

echo "[OK] oled_netinfo: Lokale venv bereit, Units installiert & aktiviert."
echo "Logs ansehen: journalctl -u <service-name> -f"