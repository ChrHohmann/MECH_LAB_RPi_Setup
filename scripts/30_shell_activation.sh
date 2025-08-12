#!/usr/bin/env bash
# scripts/30_shell_activation.sh
# Aktiviert die globale venv systemweit und pro Benutzer.
set -euo pipefail

# ---- Konfiguration (mit Default) ----
VENV_DIR="${VENV_DIR:-/opt/venv_mech_lab}"
PROFILED_SCRIPT="/etc/profile.d/activate_venv_mech_lab.sh"

# ---- Helfer: Block idempotent anhängen ----
append_if_missing() { # <file> <marker> <content>
  local file="$1"; local marker="$2"; shift 2; local content="$*"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  # Falls Marker noch nicht vorhanden, Inhalt anhängen
  if ! grep -Fq "$marker" "$file"; then
    printf "%s\n" "$content" >> "$file"
  fi
}

echo "[1/4] Systemweite Aktivierung über /etc/profile.d"
cat > "$PROFILED_SCRIPT" <<'EOS'
# /etc/profile.d/activate_venv_mech_lab.sh
VENV_DIR=/opt/venv_mech_lab

# Nur interaktive Shells aktivieren
case $- in
  *i*)
    if [ -z "$VIRTUAL_ENV" ] && [ -f "$VENV_DIR/bin/activate" ]; then
      . "$VENV_DIR/bin/activate"
    fi
    ;;
esac
EOS
chmod +x "$PROFILED_SCRIPT"

echo "[2/4] Für alle bestehenden Nutzer ~/.bashrc ergänzen und ~/.bashrc_with_venv erzeugen"
for home in /root /home/*; do
  [ -d "$home" ] || continue

  # Besitzer/Gruppe des Homeverzeichnisses ermitteln (für chown)
  owner="$(stat -c "%U" "$home" || echo root)"
  group="$(stat -c "%G" "$home" || echo root)"

  # ~/.bashrc: Auto-Activate-Block (idempotent)
  BRC="$home/.bashrc"
  append_if_missing "$BRC" "# >>> venv_mech_lab auto-activate >>>" \
"# >>> venv_mech_lab auto-activate >>>
if [ -z \"\$VIRTUAL_ENV\" ] && [ -f $VENV_DIR/bin/activate ]; then
  case \$- in *i*) . $VENV_DIR/bin/activate ;; esac
fi
# <<< venv_mech_lab auto-activate <<<"

  # ~/.bashrc_with_venv: separate RC-Datei
  BRCV="$home/.bashrc_with_venv"
  cat > "$BRCV" <<'EOV'
# Spezielle Bashrc: erst normale ~/.bashrc laden
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
# Danach globale venv aktivieren (falls noch keine aktiv ist)
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/venv_mech_lab/bin/activate ]; then
  . /opt/venv_mech_lab/bin/activate
fi
EOV

  chown "$owner:$group" "$BRC" "$BRCV" || true
  chmod 644 "$BRC" "$BRCV" || true
done

echo "[3/4] Vorlagen für künftige Nutzer nach /etc/skel"
# ~/.bashrc Ergänzung in /etc/skel
append_if_missing /etc/skel/.bashrc "# >>> venv_mech_lab auto-activate >>>" \
"# >>> venv_mech_lab auto-activate >>>
if [ -z \"\$VIRTUAL_ENV\" ] && [ -f $VENV_DIR/bin/activate ]; then
  case \$- in *i*) . $VENV_DIR/bin/activate ;; esac
fi
# <<< venv_mech_lab auto-activate <<<"

# ~/.bashrc_with_venv Vorlage
cat > /etc/skel/.bashrc_with_venv <<'EOV'
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/venv_mech_lab/bin/activate ]; then
  . /opt/venv_mech_lab/bin/activate
fi
EOV
chmod 644 /etc/skel/.bashrc_with_venv

echo "[4/4] Testausgabe"
if [ -f "$VENV_DIR/bin/activate" ]; then
  # Nicht zwingend aktivieren – nur Pfade zeigen
  echo "VENV gefunden: $VENV_DIR"
  echo "Python: $("$VENV_DIR/bin/python" -V 2>/dev/null || echo 'nicht gefunden')"
else
  echo "WARNUNG: $VENV_DIR/bin/activate nicht gefunden."
fi

echo "[OK] Shell-Aktivierung eingerichtet."
