# MECH_LAB_RPi_Setup

Dieses Repo führt auf Raspberry Pi OS folgende Schritte aus:
- Aktualisierung des Systems
- Anlegen aller Gruppen und User neben pi
- richtet eine globale Python‑venv unter `/opt/.venvs/MECH_LAB` ein
- installiert `lgpio` und `grove.py`
- installiert die Message of the day (motd) und aktiviert den erforderlichen Service
- aktiviert die venv systemweit (Login‑Shells und interaktive Shells).
- konfiguriert die VNC-Verbindung (Achtung alles andere muss manuell über raspi-config gelöst werden)
- installiert die Software zur Ansteuerung des OLED
- installiert das Rücksetzen des HOME-Directory des users STUD nach dem Neustart

## Schnellstart
```bash
sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/ChrHohmann/MECH_LAB_RPi_Setup.git MECH_LAB_RPi_Setup && cd MECH_LAB_RPi_Setup
sudo make all
