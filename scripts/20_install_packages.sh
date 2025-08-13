#!/usr/bin/env bash
set -euo pipefail
VENV_DIR=${VENV_DIR:-/opt/venv_mech_lab}

if [[ ! -x "${VENV_DIR}/bin/python" ]]; then
  echo "[FEHLER] venv unter ${VENV_DIR} nicht gefunden." >&2
  exit 1
fi

"${VENV_DIR}/bin/pip" install --upgrade pip wheel setuptools

# lgpio
"${VENV_DIR}/bin/pip" install lgpio

# grove.py aus DEINEM Fork (Branch anpassen, z. B. master)
GROVE_REPO_BRANCH=${GROVE_REPO_BRANCH:-master}
"${VENV_DIR}/bin/pip" install \
  "git+https://github.com/jonasjosi-hslu/grove.py.git@${GROVE_REPO_BRANCH}"

"${VENV_DIR}/bin/python" - <<'PY'
import importlib
pkgs = ["lgpio", "grove"]
missing=[p for p in pkgs if not importlib.util.find_spec(p)]
print("Pakete OK" if not missing else f"Fehlend: {missing}")
PY

echo "[OK] Pakete installiert"