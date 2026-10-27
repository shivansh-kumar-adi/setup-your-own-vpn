#!/usr/bin/env bash
# =============================================================================
# install-wireguard-server.sh
# Installs and configures a WireGuard VPN server on Ubuntu/Debian.
#
# Author : Shivansh Kumar (https://shivanshonline.in)
# License: MIT
#
# Usage  : sudo bash install-wireguard-server.sh
# Options (environment variables):
#   WG_PORT=51820        UDP port to listen on
#   WG_SUBNET=10.8.0     First three octets of the VPN subnet (/24)
#   WG_IFACE=wg0         WireGuard interface name
# =============================================================================
set -euo pipefail

WG_PORT="${WG_PORT:-51820}"
WG_SUBNET="${WG_SUBNET:-10.8.0}"
WG_IFACE="${WG_IFACE:-wg0}"
WG_DIR="/etc/wireguard"
CONF="${WG_DIR}/${WG_IFACE}.conf"

info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
die()   { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }

# --- 1. Pre-flight checks ----------------------------------------------------
[[ $EUID -eq 0 ]] || die "Run as root: sudo bash $0"
command -v apt-get >/dev/null || die "This script supports Debian/Ubuntu (apt) only. See docs/03-wireguard-server.md for manual steps."

if [[ -f "$CONF" ]]; then
  die "$CONF already exists. Refusing to overwrite. Back it up or remove it first."
fi

# --- 2. Install packages -----------------------------------------------------
info "Installing WireGuard and helper tools..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y wireguard qrencode iptables curl
ok "Packages installed."

# --- 3. Detect the public network interface ----------------------------------
NIC="$(ip -4 route show default | awk '{print $5; exit}')"
[[ -n "$NIC" ]] || die "Could not detect the default network interface."
info "Public network interface: ${NIC}"

# --- 4. Generate server keys -------------------------------------------------
info "Generating server key pair..."
umask 077
mkdir -p "$WG_DIR/clients"
SERVER_PRIV="$(wg genkey)"
SERVER_PUB="$(printf '%s' "$SERVER_PRIV" | wg pubkey)"
printf '%s' "$SERVER_PUB" > "${WG_DIR}/server_public.key"

# --- 5. Write the server config ----------------------------------------------
info "Writing ${CONF}..."
cat > "$CONF" <<EOF
[Interface]
Address = ${WG_SUBNET}.1/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV}
SaveConfig = false

# Allow forwarding and NAT so clients can reach the internet through this server
PostUp   = iptables -I FORWARD 1 -i %i -j ACCEPT; iptables -I FORWARD 1 -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -s ${WG_SUBNET}.0/24 -o ${NIC} -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -s ${WG_SUBNET}.0/24 -o ${NIC} -j MASQUERADE
EOF
chmod 600 "$CONF"
ok "Server config created."

# --- 6. Enable IP forwarding (persistent) ------------------------------------
info "Enabling IPv4 forwarding..."
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-wireguard.conf
sysctl --system >/dev/null
ok "IP forwarding enabled."

# --- 7. Firewall (only touch ufw if it is already active) --------------------
if command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
  info "ufw is active, opening ${WG_PORT}/udp..."
  ufw allow "${WG_PORT}/udp" >/dev/null
  ok "ufw rule added."
else
  warn "ufw is not active, no host firewall rules were changed."
  warn "Make sure ${WG_PORT}/udp is open in your cloud provider's firewall panel."
fi

# --- 8. Start and enable the service -----------------------------------------
info "Starting WireGuard..."
systemctl enable --now "wg-quick@${WG_IFACE}"
ok "WireGuard is running."

echo
wg show "$WG_IFACE"
echo
ok "Done! Next step: create a client profile with:"
echo "     sudo bash scripts/add-client.sh my-laptop"
