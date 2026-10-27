# 4. Windows Client

*Part of [Set Up Your Own VPN](../README.md) by [Shivansh Kumar](https://shivanshonline.in)*

Works on Windows 10 and 11.

## Step 1: Install WireGuard

Download the official installer from **https://www.wireguard.com/install/** (Windows section) and run it. Only download from the official site.

## Step 2: Get your profile

Copy `my-laptop.conf` from the server. Windows 10/11 include `scp`:

```powershell
scp youruser@SERVER_IP:/path/to/my-laptop.conf $HOME\Downloads\
```

(If the profile is in `/etc/wireguard/clients/`, first copy it on the server to your home folder with `sudo cp`, change its owner with `sudo chown $USER`, and delete it after transferring.)

## Step 3: Import the tunnel

1. Open the **WireGuard** app
2. Click **Import tunnel(s) from file** (or use the arrow next to *Add Tunnel*)
3. Select `my-laptop.conf`

## Step 4: Connect

Select the tunnel and click **Activate**. The status changes to *Active* and you should see **latest handshake** and growing **transfer** numbers.

## Step 5: Test

1. Search "what is my IP" in your browser. It should show the **server's** IP
2. Run the checks in [Troubleshooting → Testing for leaks](07-troubleshooting.md#testing-for-leaks)

## Tips

- **Disconnect:** click **Deactivate**
- **Start automatically:** WireGuard for Windows can run as a service; see the app's documentation
- **Delete the downloaded .conf** from Downloads after importing, since it contains your private key (the app stores its own protected copy)

## Common problems

| Problem | Fix |
|---|---|
| No handshake | Check server IP and that UDP 51820 is open in the provider firewall |
| Connected, no internet | Verify NAT and IP forwarding on server ([troubleshooting](07-troubleshooting.md)) |
| Slow pages | Add `MTU = 1380` under `[Interface]` |
