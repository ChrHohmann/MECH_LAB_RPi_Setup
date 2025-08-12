#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "${SCRIPT_DIR}/00_add_user_stud.sh"
bash "${SCRIPT_DIR}/10_create_global_venv.sh"
bash "${SCRIPT_DIR}/20_install_packages.sh"
bash "${SCRIPT_DIR}/30_shell_activation.sh"

echo -e "\n[OK] Komplett-Setup abgeschlossen. Bitte ggf. einmal neu anmelden/neu starten."
