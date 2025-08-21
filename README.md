# MECH_LAB_RPi_Setup

## Beschreibung
Dieses Repo beschreibt den Prozess, mit dem man das Betriebssystem des Raspberry Pis aufsetzt, das im Modul MECH_LAB verwendet wird. In einem ersten Schritt wird daher eine einzelne "Setup SD-Card" erzeugt. In einem zweiten Schritt wird diese SD-Karte für die Nutzung des Raspberry Pi im EEE-Netz der HSLU und im Unterricht entsprechend konfiguriert. 

Neben der Schritt für Schritt Anleitung entält diese Repo Installations-Skripte, die auf Raspberry Pi OS folgende Schritte ausführen:
- Aktualisierung des Systems
- Anlegen aller Gruppen und User neben pi
- richtet eine globale Python‑venv unter `/opt/.venvs/MECH_LAB` ein
- installiert `lgpio` und `grove.py`
- installiert die Message of the day (motd) und aktiviert den erforderlichen Service
- aktiviert die venv systemweit (Login‑Shells und interaktive Shells).
- konfiguriert die VNC-Verbindung (Achtung alles andere muss manuell über raspi-config gelöst werden)
- installiert die Software zur Ansteuerung des OLED
- installiert das Rücksetzen des HOME-Directory des users STUD nach dem Neustart

## Voraussetzungen für die Installation
- Hardware:
	- Computer/Mac 
	- SD-Card Reader
	- Raspberry Pi
	- (Micro) SD-Card
  - Micro HDMI - HDMI Adapter
  - Mouse and Keyboard
- Software:
	- Raspberry Pi Imager (kann von [official Raspberry Pi website](https://www.raspberrypi.com/software/) heruntergeladen werden).
- Others:
	- Access to Wifi "hslu" (also possible via vpn)
	- HSLU User account with access to eee-portal

## Erstellen der SD-Card 
1. Verbinde die SD-Card mit dem  Computer
2. Öffne Raspberry Pi Imager 
3. Wähle das Raspberry Pi OS das installiert werden soll
4. Wähle die SD-Card auf die das Betriebssystem installiert werden soll.  
5. Passe die Konfiguration des Betriebssystems an und wähle die folgenden Parameter :
- hostname: setup 
- ssh:
	- enable ssh
	- use password for ssh authentification
- username: pi
- password: cookie2019
- Language preferences:
	- time zone: Europe/Zurich
	- keyboard layout: ch
6. Flashe die SD-Card (dies dauert ein paar Minuten). ACHTUNG!!! Durch diesen Schritt werden alle auf der SD-Card befindlichen Daten gelöscht. Stelle sicher, dass die richtige SD-Card ausgwählt wurde.
7. Entferne die SD-Card aus dem Reader und lege sie erneut ein.
8. Erzeuge die Text-Datei "wifi.txt" und kopiere Passwort und Nutzername aus dem EEE-Portal für das Rpi in diese Datei. Speichere die Änderungen ab und entferne erneut die SD-Card.

## Konfiguration des RPi für die Nutzung des EEE Netzwerks
TBD

## Komplettkonfiguration des RPi für MECH_LAB
```bash
sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/ChrHohmann/MECH_LAB_RPi_Setup.git MECH_LAB_RPi_Setup && cd MECH_LAB_RPi_Setup
sudo make all
```

## Schritt-für-Schritt Konfiguration des RPi für MECH_LAB
```bash
sudo apt-get update -y && sudo apt-get install -y git
git clone https://github.com/ChrHohmann/MECH_LAB_RPi_Setup.git MECH_LAB_RPi_Setup && cd MECH_LAB_RPi_Setup
sudo bash scripts/05_system_update.sh
sudo bash scripts/06_groups_users.sh
sudo bash scripts/10_create_global_venv.sh
sudo bash scripts/20_install_packages.sh
sudo bash scripts/25_motd_setup.sh
sudo bash scripts/30_shell_activation.sh
sudo bash scripts/35_vnc_config.sh
sudo bash scripts/40_install_oled_netinfo.sh
sudo bash scripts/45_mech_lab_reset_home_dir.sh
```
