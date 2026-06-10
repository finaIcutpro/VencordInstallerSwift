# Vencord Installer (Swift)

A native macOS installer for [Vencord](https://github.com/Vendicated/Vencord). Written in Swift and SwiftUI. No Electron, no bundled runtime.

## Download

Get the latest release from [GitHub Releases](https://github.com/finaIcutpro/VencordInstallerSwift/releases).

1. Open `VencordInstaller.MacOS.dmg`
2. Drag **VencordInstaller** into **Applications**
3. **Quit Discord completely**, then launch the installer
4. Select your Discord install and click **Install**

> **Gatekeeper:** These builds are unsigned. On first launch, right-click the app → **Open** instead of double-clicking. You *may* also ahve to go in Privacy & Safety.

## Features

- Installs, repairs, and uninstalls Vencord
- Auto-detects Stable, PTB, Canary, and Development Discord installs
- Downloads the latest Vencord build from GitHub in parallel
- Optional [OpenAsar](https://github.com/GooseMod/OpenAsar) install/uninstall
- Lightweight — typically ~10 MB RAM at idle
- Auto detects when Discord updates & patches it (optional)

## Requirements

- macOS 14.0 or later
- An existing Discord installation
- **Full Disk Access** or **App Management** permission (required to patch Discord in `/Applications`)

### macOS blocked the installer?

Discord is a protected app. If repair/install fails or the **App Management** toggle keeps turning off:

1. **Quit Discord** and **quit the installer** (⌘Q)
2. Open **System Settings → Privacy & Security → Full Disk Access**
3. Add **Vencord Installer** and enable it (this is more reliable than App Management alone)
4. Reopen the installer from `/Applications` and try again

## Build from source

> [!TIP]
> You can always build the app on your own if you wish. I do not provide support for that tho.

To download the app, you can either download the DMG or Zip. Link: https://github.com/finaIcutpro/VencordInstallerSwift/releases

## License

GPL-3.0, see [LICENSE](LICENSE).
