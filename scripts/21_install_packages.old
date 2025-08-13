#!/usr/bin/env bash
set -euo pipefail
VENV_DIR=${VENV_DIR:-/opt/venv_mech_lab}

if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
  echo "[FEHLER] venv unter ${VENV_DIR} nicht gefunden. Erst 10_create_global_venv.sh ausführen." >&2
  exit 1
fi

echo "[1/3] Aktualisiere Pip-Tools"
"${VENV_DIR}/bin/pip" install --upgrade pip wheel setuptools

echo "[2/3] Installiere benötigte Pakete: lgpio und grove.py"
"${VENV_DIR}/bin/pip" install lgpio
"${VENV_DIR}/bin/pip" install git+https://github.com/jonasjosi-hslu/grove.py.git@master

# (Optional) Weitere nützliche HW-Pakete – bei Bedarf einkommentieren
# "${VENV_DIR}/bin/pip" install smbus2 gpiozero RPi.GPIO

echo "[3/3] Verifiziere Installation"
"${VENV_DIR}/bin/python" - <<'PY'
import importlib, sys
pkgs = ["lgpio", "grove"]
missing = []
for p in pkgs:
    try:
        importlib.import_module(p)
    except Exception as e:
        missing.append((p, str(e)))
print("Python:", sys.version)
print("Pakete OK" if not missing else f"Fehlend/Problem: {missing}")
PY

echo "[OK] Pakete installiert."
