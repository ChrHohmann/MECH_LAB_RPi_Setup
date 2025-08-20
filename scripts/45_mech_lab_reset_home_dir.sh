#!/usr/bin/env bash
# scripts/45_mech_lab_reset_home_dir.sh
# Installiert/aktualisiert das Repo ChrHohmann/mech_lab_reset_home_dir
# - Klont/updated nach TARGET_DIR
# - (optional) installiert Python-Reqs in globale venv ODER lokale .venv
# - kopiert systemd-Units (*.service/*.timer) und aktiviert sie
# - installiert ausführbare Skripte aus ./bin nach /usr/local/bin

set -euo pipefail

# --- Konfiguration (bei Bedarf beim Aufruf überschreibbar) ---
REPO_URL=${REPO_URL:-"https://github.com/ChrHohmann/mech_lab_reset_home_dir.git"}
TARGET_DIR=${TARGET_DIR:-"/opt/mech_lab_reset_home_dir"}
RUN_USER=${RUN_USER:-"pi"}              # Ausführender User
PYTHON_BIN=${PYTHON_BIN:-python3}

# Paket-Installation:
USE_LOCAL_VENV=${USE_LOCAL_VENV:-"false"}     # "true" => lokale venv: $TARGET_DIR/.venv
GLOBAL_VENV_DIR=${GLOBAL_VENV_DIR:-"/opt/venv_mech_lab"}   # genutzt wenn USE_LOCAL_VENV!="true"
LOCAL_VENV_DIR=${LOCAL_VENV_DIR:-"$TARGET_DIR/.venv"}      # genutzt wenn USE_LOCAL_VENV=="true"

SYSTEMD_DIR="/etc/systemd/system"
USR_LOCAL_BIN="/usr/local/bin"

echo "[reset-home] Repo:       $REPO_URL"
echo "[reset-home] Ziel:       $TARGET_DIR (User: $RUN_USER)"
echo "[reset-home] venv-Mode:  $( [ "$USE_LOCAL_VENV" = "true" ] && echo "lokal: $LOCAL_VENV_DIR" || echo "global: $GLOBAL_VENV_DIR" )"

# 1) Repository holen oder aktualisieren
if [[ -d "$TARGET_DIR/.git" ]]; then
  echo "[reset-home] Aktualisiere bestehendes Repo..."
  git -C "$TARGET_DIR" fetch --all --quiet || true
  git -C "$TARGET_DIR" pull --ff-only || true
else
  echo "[reset-home] Klone Repository..."
  git clone "$REPO_URL" "$TARGET_DIR"
fi
chown -R "$RUN_USER:$RUN_USER" "$TARGET_DIR" || true

# 2) Abhängigkeiten installieren (falls requirements.txt vorhanden)
if [[ -f "$TARGET_DIR/requirements.txt" ]]; then
  echo "[reset-home] requirements.txt gefunden"

  if [[ "$USE_LOCAL_VENV" == "true" ]]; then
    # Lokale, vom Rest unabhängige venv im Repo-Ordner
    if [[ ! -x "$LOCAL_VENV_DIR/bin/python" ]]; then
      echo "[reset-home] Erstelle lokale venv: $LOCAL_VENV_DIR"
      sudo -u "$RUN_USER" "$PYTHON_BIN" -m venv "$LOCAL_VENV_DIR"
    fi
    "$LOCAL_VENV_DIR/bin/pip" install --upgrade pip wheel setuptools
    "$LOCAL_VENV_DIR/bin/pip" install -r "$TARGET_DIR/requirements.txt"
    EFFECTIVE_VENV="$LOCAL_VENV_DIR"
  else
    # Globale venv verwenden
    if [[ ! -x "$GLOBAL_VENV_DIR/bin/python" ]]; then
      echo "[FEHLER] Globale venv $GLOBAL_VENV_DIR nicht gefunden. Bitte zuerst erstellen." >&2
      exit 1
    fi
    "$GLOBAL_VENV_DIR/bin/pip" install --upgrade pip wheel setuptools
    "$GLOBAL_VENV_DIR/bin/pip" install -r "$TARGET_DIR/requirements.txt"
    EFFECTIVE_VENV="$GLOBAL_VENV_DIR"
  fi
else
  echo "[reset-home] Keine requirements.txt gefunden – überspringe Pip-Install."
  EFFECTIVE_VENV=""   # nicht benötigt
fi

# 3) Executables aus ./bin nach /usr/local/bin installieren (falls vorhanden)
if compgen -G "$TARGET_DIR/bin/*" >/dev/null; then
  echo "[reset-home] Installiere Executables nach $USR_LOCAL_BIN"
  install -m 755 "$TARGET_DIR"/bin/* "$USR_LOCAL_BIN"/
else
  echo "[reset-home] Kein ./bin Verzeichnis oder keine Dateien – überspringe /usr/local/bin Install."
fi

# 4) Systemd-Units (*.service/*.timer) aus dem Repo installieren/aktivieren
mapfile -t UNIT_FILES < <(find "$TARGET_DIR" -type f \( -name "*.service" -o -name "*.timer" \))
if (( ${#UNIT_FILES[@]} > 0 )); then
  echo "[reset-home] Installiere Systemd-Units..."
  for uf in "${UNIT_FILES[@]}"; do
    base=$(basename "$uf")
    install -m 644 "$uf" "$SYSTEMD_DIR/$base"

    # Platzhalter ersetzen, falls in den Unit-Files verwendet:
    # @USER@, @APP_DIR@, @VENV_DIR@
    if grep -q "@USER@" "$SYSTEMD_DIR/$base"; then
      sed -i "s/@USER@/$RUN_USER/g" "$SYSTEMD_DIR/$base"
    fi
    if grep -q "@APP_DIR@" "$SYSTEMD_DIR/$base"; then
      sed -i "s|@APP_DIR@|$TARGET_DIR|g" "$SYSTEMD_DIR/$base"
    fi
    if grep -q "@VENV_DIR@" "$SYSTEMD_DIR/$base"; then
      # Falls keine venv verwendet wird, PATH ohne VENV setzen – ansonsten $EFFECTIVE_VENV
      VENV_PATH="${EFFECTIVE_VENV:-/usr}"
      sed -i "s|@VENV_DIR@|$VENV_PATH|g" "$SYSTEMD_DIR/$base"
    fi
  done

  systemctl daemon-reload
  for uf in "${UNIT_FILES[@]}"; do
    base=$(basename "$uf")
    echo "[reset-home] enable --now $base"
    systemctl enable --now "$base"
  done
else
  echo "[reset-home] Keine *.service/*.timer im Repo gefunden – Systemd-Setup übersprungen."
fi

echo "[OK] mech_lab_reset_home_dir installiert/aktualisiert."
echo "Tipps:"
echo "  - Logs ansehen: journalctl -u <service-name> -f"
echo "  - Service stoppen: sudo systemctl disable --now <service-name>"
