<p align="center">
  <img src="assets/app_icon.jpg" width="128" height="128" style="border-radius: 28px;" alt="macCompress Logo" />
</p>

<h1 align="center">macCompress</h1>

<p align="center">
  <strong>A Native, Clean, and High-Performance macOS Archive & Compression Utility Built with Swift & SwiftUI</strong>
  <br />
  Adheres strictly to Apple HIG · 3-Step Streamlined Flow · Smart Name Collision Handling · Zero Paid Dependencies
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-supported-formats">Supported Formats</a> •
  <a href="#-download--installation">Installation</a> •
  <a href="#-macos-integration">Finder & Dock</a> •
  <a href="#-sponsor--buy-me-a-coffee">Sponsor</a> •
  <a href="README.md">🇨🇳 简体中文版</a>
</p>

---

## 🌟 Features

- **3-Step Ultra-Clean Flow**: Drag items in → Pick format & parameters → One-click execution. No complex step-by-step wizard popups.
- **Full-Window Drag & Drop Sensing**: Seamless drag-and-drop from Finder to anywhere on the window or the Dock icon with native HIG highlight feedback.
- **Accurate Live Percentages & File Counting**: Computes true dynamic progress from the actual recursive file count (`e.g. Processing: (45/120 - 38%) wallpaper.gif`), completely eliminating the classic "stuck at 95%" problem.
- **Mid-way Cancellation Cleanup**: If cancelled midway, incomplete partial archive/extracted files are purged immediately. No broken leftovers on your Desktop.
- **Smart Directory Collision Handling**: When extracting to an existing directory name, choose between "Automatically rename and keep both `(1)`" or "Overwrite existing directory".
- **Custom Extraction Folder Naming**: Customize the target folder name before unpacking.
- **Subprocess Security & Injection Prevention**: Safe `argv: [String]` array invocation with zero shell string concatenation, fully resilient against spaces, Chinese characters, and symbols.
- **Native Out-of-the-Box Engine**: Leverages `/usr/bin/zip`, `/usr/bin/tar` (bsdtar), and `/usr/bin/hdiutil` directly from macOS.

---

## 📊 Supported Formats

| Format | Compress | Extract | Password | Split Volumes | Level Tuning | Engine |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **ZIP** | ✅ | ✅ | ✅ (AES/Standard) | ✅ | ✅ (0~9) | Native `/usr/bin/zip`, `/usr/bin/unzip` |
| **TAR** | ✅ | ✅ | ❌ | ❌ | ❌ | Native `/usr/bin/tar` (bsdtar) |
| **TAR.GZ** | ✅ | ✅ | ❌ | ❌ | ✅ (0~9) | bsdtar (built-in zlib) |
| **TAR.BZ2** | ✅ | ✅ | ❌ | ❌ | ✅ (0~9) | bsdtar (built-in bz2lib) |
| **TAR.XZ** | ✅ | ✅ | ❌ | ❌ | ✅ (0~9) | bsdtar (built-in liblzma) |
| **7-Zip (.7z)** | ✅* | ✅ | ✅ | ✅ | ✅ (0~9) | 7-Zip (auto-detected when installed) |
| **DMG / ISO** | ❌ (Disk) | ✅ | ❌ | ❌ | ❌ | Native `/usr/bin/hdiutil` read-only mount extract |
| **RAR / CAB / LZH** | ❌* | ✅* | ✅ | ❌ | ❌ | Supported via unar / 7zz / bsdtar |

---

## 🚀 Download & Installation

### Option 1: Download from Releases (Recommended)
Visit the **[Releases Page](https://github.com/qiao1225/macCompress/releases)** and download the latest `macCompress.dmg` or `macCompress-v1.0.0.zip`. Drag `macCompress.app` to your `/Applications` folder.

### Option 2: Build from Source
Requires macOS 13+ and Xcode 15+ or Swift 5.9+.
```bash
git clone https://github.com/qiao1225/macCompress.git
cd macCompress

# Compile and package as native .app
./bundle_app.sh

# Install into /Applications
cp -R macCompress.app /Applications/
```

---

## 🖥 macOS Integration

### 1. Finder Context Menu Quick Action
Run the bundled installer:
```bash
./Extensions/QuickActions/install_quick_action.sh
```
Right click any file/folder in Finder → **Quick Actions → [Compress with macCompress]**.

### 2. Dock Icon Drop
Drag files directly onto the `macCompress` icon on your Dock to launch and load them immediately.

---

## ☕️ Sponsor & Buy Me a Coffee

If you enjoy **macCompress** and find it useful in your daily workflow, consider buying the author a cup of coffee! Your support fuels ongoing open-source development ❤️

<p align="center">
  <img src="assets/donate/qrcode_1.png" width="220" alt="Donation QR Code 1" />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/donate/qrcode_2.png" width="220" alt="Donation QR Code 2" />
</p>

---

## 📄 License

Distributed under the [MIT License](LICENSE).
