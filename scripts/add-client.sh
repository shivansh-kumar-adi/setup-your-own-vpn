#!/usr/bin/env bash
# =============================================================================
# add-client.sh: create a new WireGuard client (device) profile.
#
# Author : Shivansh Kumar (https://shivanshonline.in)
# License: MIT
#
# Usage  : sudo bash add-client.sh <client-name>
# Options (environment variables):
#   ENDPOINT=1.2.3.4     Server public IP/hostname (auto-detected if unset)
#   WG_PORT=51820        Server UDP port
#   WG_SUBNET=10.8.0     Must match the server subnet
#   WG_IFACE=wg0         Interface name
#   CLIENT_DNS=1.1.1.1   DNS server given to the client
# =============================================================================
set -euo pipefail

WG_PORT="${WG_PORT:-51820}"
WG_SUBNET="${WG_SUBNET:-10.8.0}"
WG_IFACE="${WG_IFACE:-wg0}"
CLIENT_DNS="${CLIENT_DNS:-1.1.1.1}"
WG_DIR="/etc/wireguard"
CONF="${WG_DIR}/${WG_IFACE}.conf"
OUT_DIR="${WG_DIR}/clients"

die() { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }
ok()  { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash $0 <client-name>"
[[ $# -eq 1 ]] || die "Usage: sudo bash $0 <client-name>"
NAME="$1"
[[ "$NAME" =~ ^[A-Za-z0-9_-]+$ ]] || die "Name may only contain letters, numbers, - and _"
[[ -f "$CONF" ]] || die "$CONF not found. Run install-wireguard-server.sh first."
[[ ! -f "${OUT_DIR}/${NAME}.conf" ]] || die "A client named '${NAME}' already exists."

umask 077
mkdir -p "$OUT_DIR"

# --- Find the next free IP ---------------------------------------------------
LAST="$(grep -oE "${WG_SUBNET//./\\.}\.[0-9]+/32" "$CONF" | cut -d/ -f1 | awk -F. '{print $4}' | sort -n | tail -1 || true)"
NEXT=$(( ${LAST:-1} + 1 ))
[[ $NEXT -le 254 ]] || die "Subnet is full."
CLIENT_IP="${WG_SUBNET}.${NEXT}"

# --- Server details ----------------------------------------------------------
SERVER_PUB="$(wg show "$WG_IFACE" public-key 2>/dev/null || cat "${WG_DIR}/server_public.key")"
if [[ -z "${ENDPOINT:-}" ]]; then
  ENDPOINT="$(curl -fsS -4 --max-time 8 https://ifconfig.me 2>/dev/null || true)"
  [[ -n "$ENDPOINT" ]] || die "Could not auto-detect public IP. Re-run with ENDPOINT=<server-ip>"
fi

# --- Generate client keys ----------------------------------------------------
CLIENT_PRIV="$(wg genkey)"
CLIENT_PUB="$(printf '%s' "$CLIENT_PRIV" | wg pubkey)"
PSK="$(wg genpsk)"

# --- Append peer to server config (with a name marker) ------------------------
cat >> "$CONF" <<EOF

# Client: ${NAME}
[Peer]
PublicKey = ${CLIENT_PUB}
PresharedKey = ${PSK}
AllowedIPs = ${CLIENT_IP}/32
EOF

# --- Apply without dropping existing connections -----------------------------
wg syncconf "$WG_IFACE" <(wg-quick strip "$WG_IFACE")

# --- Write the client profile ------------------------------------------------
cat > "${OUT_DIR}/${NAME}.conf" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV}
Address = ${CLIENT_IP}/24
DNS = ${CLIENT_DNS}

[Peer]
PublicKey = ${SERVER_PUB}
PresharedKey = ${PSK}
Endpoint = ${ENDPOINT}:${WG_PORT}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
chmod 600 "${OUT_DIR}/${NAME}.conf"

ok "Client '${NAME}' created with IP ${CLIENT_IP}"
echo "    Profile: ${OUT_DIR}/${NAME}.conf"
echo
if command -v qrencode >/dev/null; then
  echo "Scan this QR code with the WireGuard mobile app:"
  qrencode -t ansiutf8 < "${OUT_DIR}/${NAME}.conf"
fi
echo
echo "Copy the profile to your laptop over a secure channel (scp), then delete any extra copies."
