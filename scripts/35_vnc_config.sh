#!/usr/bin/env bash
set -euo pipefail

if command -v raspi-config >/dev/null 2>&1; then
  echo "[VNC] Aktiviere VNC-Server"
  raspi-config nonint do_vnc 0 || true
else
  echo "[VNC] raspi-config nicht gefunden – bitte manuell aktivieren"
fi

echo "[VNC] Bitte folgende Schritte ggf. manuell in raspi-config setzen:"
echo "  System Options -> Boot / Auto Login -> Desktop"
echo "  Display Options -> Resolution -> 1280x720 (DMT Mode 85)"
echo "  Interface Options -> VNC -> Enable (falls oben nicht geklappt)"

echo "[OK] VNC-Konfiguration abgeschlossen (teilweise manuell)"