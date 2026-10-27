# 5. macOS Client

*Part of [Set Up Your Own VPN](../README.md) by [Shivansh Kumar](https://shivanshonline.in)*

## Method A: Official app (easiest)

1. Install **WireGuard** from the Mac App Store (the official listing by *WireGuard Development Team*)
2. Copy your profile to the Mac:
   ```bash
   scp youruser@SERVER_IP:/path/to/my-laptop.conf ~/Downloads/
   ```
3. Open WireGuard, click **Import tunnel(s) from file** (or the **+** menu) and choose the `.conf`
4. macOS asks permission to add a VPN configuration. Allow it
5. Toggle the tunnel **on**. A menu bar icon shows the status

## Method B: Command line (Homebrew)

```bash
brew install wireguard-tools
sudo mkdir -p /usr/local/etc/wireguard      # Apple Silicon Homebrew uses /opt/homebrew/etc/wireguard
sudo cp ~/Downloads/my-laptop.conf /usr/local/etc/wireguard/wg0.conf
sudo chmod 600 /usr/local/etc/wireguard/wg0.conf

sudo wg-quick up wg0       # connect
sudo wg show               # status
sudo wg-quick down wg0     # disconnect
```

Use `/opt/homebrew/etc/wireguard/` on Apple Silicon Macs if that is where your Homebrew lives (`brew --prefix` tells you).

## Test

Visit a "what is my IP" site. It should show your server's IP. Then follow [leak tests](07-troubleshooting.md#testing-for-leaks).

## Tips

- Enable **On-Demand** in the app to connect automatically on certain networks
- Delete the downloaded `.conf` after importing

Next: [7. Troubleshooting](07-troubleshooting.md)
