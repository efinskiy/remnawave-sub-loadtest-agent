#!/usr/bin/env bash

set -euo pipefail

AGENT_URL="${AGENT_URL:-https://github.com/efinskiy/remnawave-sub-loadtest-agent/raw/refs/heads/main/dist/agent}"
DEST="${DEST:-/usr/local/bin/rw-loadtest-agent}"
SERVICE="${SERVICE:-rw-loadtest-agent}"
ENV_FILE="/etc/${SERVICE}.env"

COORDINATOR="${COORDINATOR:?set COORDINATOR=https://control.example.com}"
AGENT_TOKEN="${AGENT_TOKEN:?set AGENT_TOKEN=your-shared-secret}"

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"

dl() { # dl <url> <dest>
  if command -v curl >/dev/null 2>&1; then $SUDO curl -fsSL "$1" -o "$2";
  elif command -v wget >/dev/null 2>&1; then $SUDO wget -qO "$2" "$1";
  else echo "need curl or wget"; exit 1; fi
}

echo "==> downloading agent binary"
echo "    $AGENT_URL -> $DEST"
dl "$AGENT_URL" "$DEST"
$SUDO chmod +x "$DEST"

if command -v systemctl >/dev/null 2>&1; then
  echo "==> writing $ENV_FILE (0600)"
  $SUDO tee "$ENV_FILE" >/dev/null <<ENV
COORDINATOR=$COORDINATOR
AGENT_TOKEN=$AGENT_TOKEN
ENV
  $SUDO chmod 600 "$ENV_FILE"

  echo "==> installing systemd service: $SERVICE"
  $SUDO tee "/etc/systemd/system/${SERVICE}.service" >/dev/null <<UNIT
[Unit]
Description=Remnawave sub load-test agent
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=$ENV_FILE
ExecStart=$DEST -coordinator \${COORDINATOR} -agent-token \${AGENT_TOKEN} -i-am-authorized
Restart=always
RestartSec=3
DynamicUser=yes
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes

[Install]
WantedBy=multi-user.target
UNIT

  $SUDO systemctl daemon-reload
  $SUDO systemctl enable --now "$SERVICE"
  echo "==> started. follow logs with:  journalctl -u $SERVICE -f"
else
  echo "==> systemd not found; run manually:"
  echo "    $DEST -coordinator $COORDINATOR -agent-token <token> -i-am-authorized"
fi
