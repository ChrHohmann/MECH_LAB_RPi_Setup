# MECH_LAB_VENV_Setup

Dieses Repo richtet auf Raspberry Pi OS eine globale Python‑venv unter `/opt/venv_mech_lab` ein, installiert `lgpio` und `grove.py`, und aktiviert die venv systemweit (Login‑Shells und interaktive Shells).

## Schnellstart
```bash
sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/ChrHohmann/MECH_LAB_VENV_Setup.git MECH_LAB_VENV_Setup && cd MECH_LAB_VENV_Setup
sudo make all
