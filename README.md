# kobo-bluetooth-reconnect

Automatically reconnects your Kobo Bluetooth Remote after the device wakes from sleep. No menu navigation required.

---

### The Problem

Every time a Kobo goes to sleep it drops the Bluetooth connection to the paired remote. To use the remote after waking you have to navigate to **Settings → Bluetooth Connection** and tap the saved remote entry to reconnect it manually.

---

### The Fix

A lightweight background script that watches for the remote's Bluetooth advertisements after wake and automatically reconnects it. It finds your remote by name from the existing pairing data. No MAC address configuration needed.

---

### How It Works

#### Basic

When your Kobo wakes from sleep, the script notices the remote becoming visible over Bluetooth and sends a reconnect command automatically. This happens in the background within 3 to 15 seconds of waking.

#### Technical

The mod installs two files. A udev rule at `/etc/udev/rules.d/97-bt-reconnect.rules` fires whenever the onboard storage partition mounts during boot, which launches the main script at `/usr/local/Kobo/bt-reconnect.sh`. On startup the script reads `/data/misc/bluedroid/bt_config.conf` (Kobo's MediaTek Bluetooth pairing database) and finds the MAC address of the paired Kobo Remote by matching the device name. It converts that MAC to the D-Bus object path format used by Kobo's MTK Bluetooth stack and starts a `dbus-monitor` process writing all Bluetooth events to a temp file. Every few seconds it checks that file for the remote's MAC address. When the remote wakes up it begins advertising over Bluetooth, the script detects this, waits briefly, then sends a connect command via `com.kobo.mtk.bluedroid`. The result is logged in `/tmp/bt-reconnect.log` and the cycle resets ready for the next wake.

---

### Compatibility

| Device | Status |
|---|---|
| Kobo Libra Colour | ✅ Confirmed working |
| Kobo Clara BW | 🔲 Untested |
| Kobo Clara Colour | 🔲 Untested |
| Kobo Elipsa 2E | 🔲 Untested |
| Kobo Sage | 🔲 Untested |
| Kobo Libra 2 | 🔲 Untested |

> This mod requires the MTK Bluetooth stack used in Kobo devices released from approximately 2023 onwards. Older Kobo devices (i.MX6 platform) use a different Bluetooth stack and are **not** supported.
>
> If you test this on a device not listed here please open an issue and report your results so the table can be updated.

---

### Files: What Gets Installed and What They Are For

| File | Purpose |
|---|---|
| `/usr/local/Kobo/bt-reconnect.sh` | The main script that monitors Bluetooth events and reconnects the remote when it is seen after wake |
| `/etc/udev/rules.d/97-bt-reconnect.rules` | A udev rule that automatically launches the script on every boot. Using a udev rule rather than modifying the system boot script means the mod survives firmware updates |

The following temporary files are created by the script while it is running and are automatically removed on reboot:

| File | Purpose |
|---|---|
| `/tmp/bt-reconnect.log` | Log of all script activity, useful for troubleshooting |
| `/tmp/bt-connecting.lock` | Lock file that prevents duplicate connection attempts |
| `/tmp/bt-dbus.log` | Temporary capture of Bluetooth D-Bus events used to detect the remote |

---

## Prerequisites

- Your Kobo Remote must be paired via **Settings → Bluetooth Connection** before installing. It does not need to be actively connected, just paired.
- SSH is only required for the Manual Install and Manual Uninstall methods. More on that below.

---

## Automatic: No SSH Required

### Auto Install

**Step 1** Make sure your Kobo Remote is paired via **Settings → Bluetooth Connection**.

**Step 2** Connect your Kobo to your computer via USB.

**Step 3** Open the `.kobo` folder on your Kobo's storage.
- On Windows: enable **Show hidden items** in File Explorer
- On Mac: press `Cmd + Shift + .` to show hidden folders

**Step 4** Copy `KoboRoot.tgz` from the `Auto Install` folder into the `.kobo` folder on your device.

**Step 5** Safely eject the Kobo from your computer. The Kobo will reboot and install the mod automatically.

**Step 6** Test the mod by putting the Kobo to sleep for at least 15 seconds, then waking it and waiting up to 15 seconds. The remote should reconnect on its own.

---

### Auto Uninstall

**Step 1** Connect your Kobo to your computer via USB.

**Step 2** Open the `.kobo` folder on your Kobo's storage.
- On Windows: enable **Show hidden items** in File Explorer
- On Mac: press `Cmd + Shift + .` to show hidden folders

**Step 3** Copy `KoboRoot.tgz` from the `Auto Uninstall` folder into the `.kobo` folder on your device.

**Step 4** Safely eject. The Kobo will reboot and remove all mod files automatically.

---

## Manual Install and Uninstall: SSH Required

### Enabling SSH

SSH lets you connect to your Kobo's command line from your computer. You will need this for the manual install and uninstall methods.

**Step 1** Connect your Kobo to your computer via USB.

**Step 2** Open the `.kobo` folder on your Kobo's storage.
- On Windows: enable **Show hidden items** in File Explorer
- On Mac: press `Cmd + Shift + .` to show hidden folders

**Step 3** Find the file named `ssh-disabled` and rename it to `ssh-enabled`.

**Step 4** Safely eject the Kobo from your computer and restart it.

**Step 5** Find your Kobo's IP address at **Settings → Device information**.

**Step 6** Connect via SSH:
- **Mac/Linux:** open Terminal and run:
  ```sh
  ssh root@<your-kobo-ip>
  ```
- **Windows:** download and open [PuTTY](https://www.putty.org/), enter your Kobo's IP address in the Host Name field, and click Open. Log in as `root`.

You may be prompted to set a password on first connection. If you ever lose the password, disabling and re-enabling SSH should allow you to set a new one.

---

#### Manual Install

The manual install uses `wget` to download both files directly to your Kobo over the internet. Your Kobo must be connected to Wi-Fi.

**Step 1** Enable SSH (see above) and connect to your Kobo.

**Step 2** The following command will download the main reconnect script and save it to the correct location on your Kobo:
```sh
wget -O /usr/local/Kobo/bt-reconnect.sh https://raw.githubusercontent.com/xriri/kobo-bluetooth-reconnect/main/Manual%20Install/bt-reconnect.sh
```

**Step 3** The following command will give the Kobo permission to run the script:
```sh
chmod +x /usr/local/Kobo/bt-reconnect.sh
```

**Step 4** The following command will download the udev rule and save it to the correct location. This rule tells the Kobo to automatically start the reconnect script on every boot:
```sh
wget -O /etc/udev/rules.d/97-bt-reconnect.rules https://raw.githubusercontent.com/xriri/kobo-bluetooth-reconnect/main/Manual%20Install/97-bt-reconnect.rules
```

**Step 5** The following command will reboot the Kobo. This makes the udev rule take effect and confirms the script starts correctly on boot:
```sh
reboot
```

**Step 6** Once the Kobo has rebooted, test the mod by putting it to sleep for at least 15 seconds, then waking it and waiting up to 15 seconds. The remote should reconnect on its own.

If the remote does not reconnect see the [Checking the Log](#checking-the-log) and [Troubleshooting](#troubleshooting) sections below.

---

#### Manual Uninstall

**Step 1** Connect to your Kobo via SSH.

**Step 2** The following command will remove the udev rule so the script no longer launches on boot:
```sh
rm -f /etc/udev/rules.d/97-bt-reconnect.rules
```

**Step 3** The following command will remove the reconnect script:
```sh
rm -f /usr/local/Kobo/bt-reconnect.sh
```

**Step 4** The following commands will remove the temporary log and lock files created by the script:
```sh
rm -f /tmp/bt-reconnect.log
rm -f /tmp/bt-connecting.lock
rm -f /tmp/bt-dbus.log
```

**Step 5** The following command will reboot the Kobo. This stops all running processes related to the mod and confirms everything has been cleanly removed:
```sh
reboot
```

---

## Checking the Log

The following command will display the log file:
```sh
cat /tmp/bt-reconnect.log
```

A successful run looks like this:
```
Wed Mar 18 22:36:01 PDT 2026: bt-reconnect started
Wed Mar 18 22:36:01 PDT 2026: Found Kobo Remote MAC: AA:BB:CC:DD:EE:FF
Wed Mar 18 22:36:01 PDT 2026: Using device path: /org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF
Wed Mar 18 22:37:58 PDT 2026: Remote seen, waiting 3s...
Wed Mar 18 22:38:01 PDT 2026: Result: method return sender=:1.841 -> dest=:1.1167 reply_serial=2
Wed Mar 18 22:38:09 PDT 2026: Connected!
```

Common result messages after a connect attempt:

| Result | Meaning |
|---|---|
| `method return ...` | Connect command accepted, success |
| `Error org.bluez.Error.Failed: connection failed` | Remote not ready yet, will retry on next appearance |
| `Error org.freedesktop.DBus.Error.UnknownObject` | Remote disappeared from scan, will retry on next appearance |

---

## Timing Settings

If the remote is not connecting reliably you can adjust the timing variables near the top of `/usr/local/Kobo/bt-reconnect.sh` via SSH:

```sh
WAIT_BEFORE_CONNECT=3   # seconds to wait after seeing remote before attempting connection
WAIT_AFTER_CONNECT=3    # seconds to wait after connection attempt before checking success
RETRY_DELAY=2           # seconds between retry attempts if connection failed
```

Increase `WAIT_BEFORE_CONNECT` if you see repeated `connection failed` errors in the log. Decrease it if the connection is taking too long after wake.

---

## Troubleshooting

**Remote not connecting after wake**

The following command will display the log file which may help identify the problem:
```sh
cat /tmp/bt-reconnect.log
```
If you see repeated `connection failed` errors, try increasing `WAIT_BEFORE_CONNECT` in the script. See the Timing Settings section above.

---

**"Could not find paired Kobo Remote" in the log**

The remote is not paired or was paired after the script last started. Go to **Settings → Bluetooth Connection** and pair the remote, then reboot the Kobo:
```sh
reboot
```

---

**Script not running after reboot**

The following command will check whether the udev rule that launches the script is present:
```sh
cat /etc/udev/rules.d/97-bt-reconnect.rules
```
If the file is missing, repeat the install.

---

**Does the mod survive a Kobo firmware update?**

Yes. Firmware updates overwrite `/etc/init.d/rcS` but do not touch files in `/usr/local/Kobo/` or udev rules in `/etc/udev/rules.d/`. The mod will continue working after any firmware update without any action required.

---

## Contributing

Pull requests welcome. If you test this on a device not in the compatibility table please open an issue with your device model and firmware version.

---

## License

MIT
