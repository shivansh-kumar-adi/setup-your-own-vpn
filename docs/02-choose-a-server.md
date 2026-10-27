# 2. Choose a Server

*Part of [Set Up Your Own VPN](../README.md) by [Shivansh Kumar](https://shivanshonline.in)*

Your VPN server must be a machine that is **always on** and **reachable from the internet** on a UDP port.

## Option A: Cloud VPS (recommended for beginners)

Rent a small virtual private server from any provider. Look for:

| Requirement | Recommendation |
|---|---|
| OS | Ubuntu 22.04 / 24.04 LTS or Debian 12 |
| Size | 1 vCPU, 512 MB to 1 GB RAM is enough |
| Network | Public **IPv4** address; UDP not blocked |
| Region | Choose close to you for speed, or in another country if you need that location |
| Bandwidth | Check monthly traffic allowance; VPN traffic counts |
| Access | Root or sudo via SSH |

Provider pricing and free tiers change often, so compare current offers. Read the provider's terms of service to ensure VPN use is permitted.

## Option B: Home server (Raspberry Pi or old PC)

Useful for securely reaching your **home network** while away. You need:

1. A device running Linux 24/7
2. **Port forwarding** of `51820/udp` on your router to the device
3. A **dynamic DNS** name (since home IPs change) if you lack a static IP
4. A public IP. If your ISP uses **CGNAT** (you share an IP with others), port forwarding will not work; consider a VPS or Tailscale instead

Note that a home server gives you a *residential* IP at home, so it won't change your apparent location when you are at home.

## Connecting to your server over SSH

From your laptop (Windows 10/11, macOS, and Linux all include an SSH client):

```bash
ssh root@SERVER_IP
# or, if your provider created a normal user:
ssh ubuntu@SERVER_IP
```

First-time tasks on a new server:

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot            # if a kernel update was installed
```

## Open the port at your provider

Many providers have a **cloud firewall / security group** separate from the server. Allow inbound:

| Port | Protocol | Purpose |
|---|---|---|
| 22 | TCP | SSH |
| 51820 | UDP | WireGuard |

Next: [3. WireGuard server setup](03-wireguard-server.md)
