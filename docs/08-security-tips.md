# 8. Security Tips

*Part of [Set Up Your Own VPN](../README.md) by [Shivansh Kumar](https://shivanshonline.in)*

A VPN server is a doorway into your network. Keep it tight.

## 1. Protect keys

- Private keys stay on their own device. Never email, chat, or commit them
- `chmod 600` all `.conf` and `.key` files
- Use a **separate key pair per device** so a single device can be revoked
- Delete leftover copies of profiles after importing them
- The included `.gitignore` blocks `*.conf` and `*.key`. Don't remove those lines

## 2. Harden SSH

```bash
# Create a normal user with sudo
adduser vpnadmin && usermod -aG sudo vpnadmin

# On your laptop: create and copy an SSH key
ssh-keygen -t ed25519
ssh-copy-id vpnadmin@SERVER_IP
```

Then edit `/etc/ssh/sshd_config.d/99-hardening.conf`:

```
PasswordAuthentication no
PermitRootLogin no
```

```bash
sudo sshd -t && sudo systemctl restart ssh    # test the config first
```

Keep your current session open and test a second login before closing it.

## 3. Firewall: expose only what's needed

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 51820/udp
sudo ufw enable
```

## 4. Automatic security updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

## 5. Optional: fail2ban for SSH

```bash
sudo apt install -y fail2ban
sudo systemctl enable --now fail2ban
```

## 6. Revoke lost devices immediately

```bash
sudo bash scripts/remove-client.sh my-laptop
```

## 7. Rotate keys periodically

Generate new client keys every so often (for example yearly, or whenever you suspect exposure) by removing and re-adding the client.

## 8. Monitor

```bash
sudo wg show
sudo journalctl -u wg-quick@wg0
```

Unknown peers cannot appear unless someone edited your config, so unexpected entries mean the server may be compromised.

## 9. Legal and ethical use

Follow your country's laws and your provider's terms. Don't use your server for abuse; the server's IP is tied to your account.

## Checklist

- [ ] SSH keys only, root login off
- [ ] Firewall on, minimal ports
- [ ] Auto-updates on
- [ ] One key pair per device
- [ ] Secrets never in Git
- [ ] Leak tests passed
