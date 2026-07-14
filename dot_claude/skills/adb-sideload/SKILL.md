---
name: adb-sideload
description: Scan LAN for ADB devices, connect, and sideload APK files. Trigger: /adb-sideload
---

# ADB Sideload Skill

Scan your LAN for Android devices with ADB over TCP (port 5555), connect to selected device, and install APK files.

## When to Use

- User wants to find ADB devices on local network
- User wants to sideload/install an APK to a remote Android device
- User mentions "adb", "sideload", "install apk", "tv box", "android tv", "fire tv"

## Prerequisites

- `nmap` installed (`scoop install nmap` on Windows, `apt install nmap` on Linux)
- `adb` installed (Android platform-tools)
- Both available in `$PATH`

## Instructions

1. **Run the script** with appropriate flags:

```bash
bash ~/.claude/scripts/adb-sideload.sh
```

Options:
- `--subnet CIDR` — Override auto-detected subnet (e.g. `192.168.1.0/24`)
- `--apk PATH` — Pre-select APK to install
- `--connect-only` — Only scan and connect, skip APK install

2. **Interactive flow** — The script will:
   - Auto-detect your LAN subnet
   - Scan for devices with port 5555 open
   - Connect to each found device and probe identity (model, manufacturer, Android version)
   - Present device list for selection
   - If single device found, auto-select it
   - List APK files in current directory or prompt for path
   - Install selected APK via `adb install`

3. **After install** — Optionally launch the app:

```bash
adb -s <IP>:5555 shell am start -n <package>/<activity>
```

Use `adb shell pm dump <package> | grep -A1 MAIN` to find the launcher activity if unknown.

4. **Cleanup** — Disconnect when done:

```bash
adb disconnect <IP>:5555
```

## Safety Notes

- ADB over TCP is **unencrypted and unauthenticated**. Only use on trusted LANs.
- Disconnect devices after use on shared networks.
- Some devices require `adb tcpip 5555` first (from USB connection) before they accept network connections.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No devices found | Try `--subnet` with different CIDR; device may be on VLAN/guest network |
| Connection refused | Device may need `adb tcpip 5555` via USB first |
| Install failed | Check architecture (arm64 vs armeabi); try `adb install -r` for reinstall |
| Device not listed | Run `nmap -p 5555 -Pn <subnet>` to skip host discovery |
