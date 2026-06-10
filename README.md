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

## Requirements

- macOS 14.0 or later
- An existing Discord installation
- Full Disk Access may be required if Discord is installed in `/Applications`

## Build from source

> [!TIP]
> You can always build the app on your own if you wish. I do not provide support for that tho.
To download the app, you can either download the DMG or Zip. Link: https://github.com/finaIcutpro/VencordInstallerSwift/releases

## License

GPL-3.0, see [LICENSE](LICENSE).
