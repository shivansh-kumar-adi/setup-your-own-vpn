# 3. WireGuard Server Setup (Manual)

*Part of [Set Up Your Own VPN](../README.md) by [Shivansh Kumar](https://shivanshonline.in)*

> Prefer automation? Run `sudo bash scripts/install-wireguard-server.sh` instead. This page explains what that script does, command by command. Commands assume Ubuntu/Debian and a root shell (`sudo -i`).

## Step 1: Install WireGuard

```bash
apt update
apt install -y wireguard qrencode
```

## Step 2: Generate the server keys

```bash
cd /etc/wireguard
umask 077
wg genkey | tee server_private.key | wg pubkey > server_public.key
cat server_public.key       # you'll give this to clients
```

`umask 077` makes new files readable only by root.

## Step 3: Find your public network interface

```bash
ip -4 route show default
# example output: default via 203.0.113.1 dev eth0 ...
```

The word after `dev` (here `eth0`) is your interface. It may be `ens3`, `enp1s0`, etc.

## Step 4: Create `/etc/wireguard/wg0.conf`

```ini
[Interface]
Address = 10.8.0.1/24
ListenPort = 51820
PrivateKey = <paste contents of server_private.key>

PostUp   = iptables -I FORWARD 1 -i %i -j ACCEPT; iptables -I FORWARD 1 -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

Replace `eth0` with your interface from Step 3, then lock the file down:

```bash
chmod 600 /etc/wireguard/wg0.conf
```

| Line | Meaning |
|---|---|
| `Address` | The server's IP inside the VPN |
| `ListenPort` | UDP port clients connect to |
| `PrivateKey` | The server's secret key |
| `PostUp` / `PostDown` | Firewall rules added when the tunnel starts and removed when it stops: allow forwarding, and NAT (masquerade) outgoing packets |

## Step 5: Enable IP forwarding

```bash
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/99-wireguard.conf
sysctl --system
sysctl net.ipv4.ip_forward     # should print 1
```

Without this the server will not route packets between the tunnel and the internet.

## Step 6: Open the firewall

If you use `ufw`:

```bash
ufw allow OpenSSH
ufw allow 51820/udp
ufw enable          # only after allowing SSH, or you will lock yourself out!
ufw status
```

Also open `51820/udp` in your cloud provider's panel.

## Step 7: Start WireGuard and enable at boot

```bash
systemctl enable --now wg-quick@wg0
wg show
```

You should see the `wg0` interface listening on port 51820.

## Step 8: Add a client (peer)

On the **client** (or on the server for convenience) generate keys:

```bash
wg genkey | tee client_private.key | wg pubkey > client_public.key
```

Add the client's **public** key to the server config:

```ini
[Peer]
PublicKey = <contents of client_public.key>
AllowedIPs = 10.8.0.2/32
```

Apply the change without restarting:

```bash
wg syncconf wg0 <(wg-quick strip wg0)
```

Now create the client profile (this file goes on the laptop):

```ini
[Interface]
PrivateKey = <contents of client_private.key>
Address = 10.8.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <contents of server_public.key>
Endpoint = <SERVER_PUBLIC_IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

> The script `scripts/add-client.sh` does all of Step 8 for you, including a preshared key and a QR code.

## Step 9: Check the connection

After the client connects:

```bash
wg show
```

A healthy peer shows a recent `latest handshake` and increasing `transfer` counters.

## Managing clients

| Task | How |
|---|---|
| Add a device | `sudo bash scripts/add-client.sh <name>` |
| Remove a device | `sudo bash scripts/remove-client.sh <name>` |
| List peers/status | `sudo wg show` |
| Restart | `sudo systemctl restart wg-quick@wg0` |
| Logs | `sudo journalctl -u wg-quick@wg0` |

Next: pick your client guide: [Windows](04-client-windows.md) · [macOS](05-client-macos.md) · [Linux](06-client-linux.md)
