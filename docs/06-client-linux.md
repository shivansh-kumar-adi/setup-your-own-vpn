# 6. Linux Client

*Part of [Set Up Your Own VPN](../README.md) by [Shivansh Kumar](https://shivanshonline.in)*

## Step 1: Install

```bash
# Debian / Ubuntu / Mint
sudo apt install -y wireguard resolvconf

# Fedora
sudo dnf install -y wireguard-tools

# Arch
sudo pacman -S wireguard-tools
```

(`resolvconf` or `systemd-resolved` is needed for the `DNS =` line to work in `wg-quick`.)

## Step 2: Install the profile

```bash
scp youruser@SERVER_IP:/path/to/my-laptop.conf .
sudo mv my-laptop.conf /etc/wireguard/wg0.conf
sudo chown root:root /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
```

## Step 3: Connect and disconnect

```bash
sudo wg-quick up wg0
sudo wg show
sudo wg-quick down wg0
```

## Step 4: Start automatically at boot (optional)

```bash
sudo systemctl enable --now wg-quick@wg0
```

## Alternative: NetworkManager (GUI-friendly)

```bash
sudo nmcli connection import type wireguard file ./my-laptop.conf
nmcli connection up my-laptop
nmcli connection down my-laptop
```

## Test

```bash
curl -4 https://ifconfig.me      # should print the SERVER's IP
```

See also [leak tests](07-troubleshooting.md#testing-for-leaks).
