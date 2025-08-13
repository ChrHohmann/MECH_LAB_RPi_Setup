#!/usr/bin/env bash
set -euo pipefail

VENV_DIR="${VENV_DIR:-/opt/venv_mech_lab}"
PROFILED_SCRIPT="/etc/profile.d/activate_venv_mech_lab.sh"

append_if_missing() { # <file> <marker> <content>
  local file="$1"; local marker="$2"; shift 2; local content="$*"
  mkdir -p "$(dirname "$file")"; touch "$file"
  grep -Fq "$marker" "$file" || printf "%s\n" "$content" >> "$file"
}

cat > "$PROFILED_SCRIPT" <<'EOS'
# /etc/profile.d/activate_venv_mech_lab.sh
VENV_DIR=/opt/venv_mech_lab
case $- in *i*) if [ -z "$VIRTUAL_ENV" ] && [ -f "$VENV_DIR/bin/activate" ]; then . "$VENV_DIR/bin/activate"; fi;; esac
EOS
chmod +x "$PROFILED_SCRIPT"

for home in /root /home/*; do
  [ -d "$home" ] || continue
  owner="$(stat -c "%U" "$home" || echo root)"; group="$(stat -c "%G" "$home" || echo root)"
  BRC="$home/.bashrc"
  append_if_missing "$BRC" "# >>> venv_mech_lab auto-activate >>>" \
"# >>> venv_mech_lab auto-activate >>>\nif [ -z \"$VIRTUAL_ENV\" ] && [ -f $VENV_DIR/bin/activate ]; then\n  case \$- in *i*) . $VENV_DIR/bin/activate ;; esac\nfi\n# <<< venv_mech_lab auto-activate <<<"
  BRCV="$home/.bashrc_with_venv"
  cat > "$BRCV" <<'EOV'
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/venv_mech_lab/bin/activate ]; then . /opt/venv_mech_lab/bin/activate; fi
EOV
  chown "$owner:$group" "$BRC" "$BRCV" || true; chmod 644 "$BRC" "$BRCV" || true
done

append_if_missing /etc/skel/.bashrc "# >>> venv_mech_lab auto-activate >>>" \
"# >>> venv_mech_lab auto-activate >>>\nif [ -z \"$VIRTUAL_ENV\" ] && [ -f $VENV_DIR/bin/activate ]; then\n  case \$- in *i*) . $VENV_DIR/bin/activate ;; esac\nfi\n# <<< venv_mech_lab auto-activate <<<"

cat > /etc/skel/.bashrc_with_venv <<'EOV'
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi
if [ -z "$VIRTUAL_ENV" ] && [ -f /opt/venv_mech_lab/bin/activate ]; then . /opt/venv_mech_lab/bin/activate; fi
EOV
chmod 644 /etc/skel/.bashrc_with_venv

if [ -f "$VENV_DIR/bin/python" ]; then
  echo "Python: $($VENV_DIR/bin/python -V 2>/dev/null || true)"
fi

echo "[OK] Shell-Aktivierung eingerichtet"