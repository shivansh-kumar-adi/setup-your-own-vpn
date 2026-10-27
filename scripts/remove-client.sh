#!/usr/bin/env bash
# =============================================================================
# remove-client.sh: revoke a client created with add-client.sh.
#
# Author : Shivansh Kumar (https://shivanshonline.in)
# License: MIT
#
# Usage  : sudo bash remove-client.sh <client-name>
# =============================================================================
set -euo pipefail

WG_IFACE="${WG_IFACE:-wg0}"
CONF="/etc/wireguard/${WG_IFACE}.conf"
OUT_DIR="/etc/wireguard/clients"

die() { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }
ok()  { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }

[[ $EUID -eq 0 ]] || die "Run as root."
[[ $# -eq 1 ]] || die "Usage: sudo bash $0 <client-name>"
NAME="$1"
[[ "$NAME" =~ ^[A-Za-z0-9_-]+$ ]] || die "Invalid name."
grep -qx "# Client: ${NAME}" "$CONF" || die "Client '${NAME}' not found in ${CONF}."

cp "$CONF" "${CONF}.bak.$(date +%s)"

# Remove the block that starts at "# Client: NAME" up to the next "# Client:" or end of file
awk -v name="$NAME" '
  $0 == "# Client: " name { skip=1; next }
  /^# Client: / && skip   { skip=0 }
  !skip                   { print }
' "$CONF" > "${CONF}.new"
chmod 600 "${CONF}.new"
mv "${CONF}.new" "$CONF"

rm -f "${OUT_DIR}/${NAME}.conf"
wg syncconf "$WG_IFACE" <(wg-quick strip "$WG_IFACE")
ok "Client '${NAME}' revoked."
