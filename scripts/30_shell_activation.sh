!/usr/bin/env bash
set -euo pipefail
ENV_DIR=${VENV_DIR:-/opt/venv_mech_lab}
PROFILED_SCRIPT=/etc/profile.d/activate_venv_mech_lab.sh

append_if_missing() { # <file> <marker> <content>
  local file="$1"; local marker="$2"; shift 2; local content="$*"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  grep -Fq "$marker" "$file" || echo -e "$content" >> "$file"
}

echo "[1/4] Systemweite Aktivierung über /etc/profile.d"
cat > "$PROFILED_SCRIPT" <<'EOS'
# /etc/profile.d/activate_venv_mech_lab.sh
VENV_DIR=/opt/venv_mech_lab
# Nur interaktive Shells aktivieren
case $- in
  *i*)
    if [ -d "$VENV_DIR" ] && [ -f "$VENV_DIR/bin/activate" ]; then
      # nur aktivieren, wenn noch keine venv aktiv ist
      if [ -z "$VIRTUAL_ENV" ]; then
        . "$VENV_DIR/bin/activate"
      fi
    fi
    ;;
esac
EOS
chmod +x "$PROFILED_SCRIPT"

echo "[2/4] Für alle bestehenden Nutzer ~/.bashrc ergänzen und ~/.bashrc_with_venv erzeugen"
for home in /root /home/*; do
  [ -d "$home" ] || continue
  user=$(basename "$home")

  # ~/.bashrc ergänzen (idempotent)
  BRC="$home/.bashrc"
  append_if_missing "$BRC" "# >>> venv_mech_lab auto-activate >>>" "# >>> venv_mech_lab auto-activate >>>\nif [ -d $VENV_DIR ] && [ -f $VENV_DIR/bin/activate ]; then\n  case $- in *i*) [ -z \"$VIRTUAL_ENV\" ] && . $VENV_DIR/bin/activate ;; esac\nfi\n# <<< venv_mech_lab auto-activate <<<\n"

  # ~/.bashrc_with_venv anlegen
  BRCV="$home/.bashrc_with_venv"
  cat > "$BRCV" <<'EOV'
# Spezielle Bashrc, die zunächst die normale ~/.bashrc lädt
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
# Dann die globale venv aktivieren, falls noch keine aktiv ist
if [ -d /opt/venv_mech_lab ] && [ -f /opt/venv_mech_lab/bin/activate ]; then
  if [ -z "$VIRTUAL_ENV" ]; then
    . /opt/venv_mech_lab/bin/activate
  fi
fi
EOV
  chown $(stat -c "%U:%G" "$home") "$BRC" "$BRCV" || true
  chmod 644 "$BRC" "$BRCV" || true

done

echo "[3/4] Vorlagen für künftige Nutzer nach /etc/skel"
# ~/.bashrc Ergänzung
append_if_missing /etc/skel/.bashrc "# >>> venv_mech_lab auto-activate >>>" "# >>> venv_mech_lab auto-activate >>>\nif [ -d $VENV_DIR ] && [ -f $VENV_DIR/bin/activate ]; then\n  case $- in *i*) [ -z \"$VIRTUAL_ENV\" ] && . $VENV_DIR/bin/activate ;; esac\nfi\n# <<< venv_mech_lab auto-activate <<<\n"
# ~/.bashrc_with_venv Vorlage
cat > /etc/skel/.bashrc_with_venv <<'EOV'
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
if [ -d /opt/venv_mech_lab ] && [ -f /opt/venv_mech_lab/bin/activate ]; then
  if [ -z "$VIRTUAL_ENV" ]; then
    . /opt/venv_mech_lab/bin/activate
  fi
fi
EOV
chmod 644 /etc/skel/.bashrc_with_venv

echo "[4/4] Testausgabe"
. "$VENV_DIR/bin/activate" || true
which python || true
python -c 'import sys; print(sys.executable)' || true

echo "[OK] Shell-Aktivierung eingerichtet."
