<p align="center">
  <img src="assets/app_icon.jpg" width="128" height="128" style="border-radius: 28px;" alt="macCompress Logo" />
</p>

<h1 align="center">macCompress</h1>

<p align="center">
  <strong>一款基于 Swift 5.9+ / SwiftUI 构建的 macOS 原生极简高效通用压缩与解压工具</strong>
  <br />
  遵循 Apple HIG 纯正原生设计规范 · 3步极简直达 · 智能同名冲突处理 · 零第三方收费依赖
</p>

<p align="center">
  <a href="#-核心特性">特性亮点</a> •
  <a href="#-支持格式矩阵">格式矩阵</a> •
  <a href="#-下载与安装">快速安装</a> •
  <a href="#-系统级深度集成">访达与Dock集成</a> •
  <a href="#-赞赏与支持">请作者喝咖啡</a> •
  <a href="README_EN.md">English Version</a>
</p>

---

## 🌟 核心特性

- **极简 3 步直达流**：拖入文件/文件夹 → 选择格式与参数 → 一键执行，无繁琐多步向导。
- **全屏智能拖拽感知**：支持从访达直接拖入任意区域或屏幕下方的 Dock 图标，悬停具有柔和的 HIG 原生高亮反馈；在解压标签页拖入直接进入解压流程。
- **活百分比与精准文件计数**：根据真实递归文件数动态计算进度（例如：`正在处理: (45/120 - 38%) wallpaper.gif`），告别卡顿在 95% 的死板体验；任务完成弹出醒目横幅。
- **中途取消安全保护**：若中途手动取消压缩或解压，内核立即自动清理半成品未完成文件，不在桌面留坏文件。
- **同名文件夹智能冲突处理**：解压若遇同名文件夹，支持“自动改名并保留两者 (1)”或“替换覆盖”，避免误冲数据。
- **解压支持自定义命名**：支持在解压前将生成的文件夹重命名为任意自定义名称。
- **原生安全与防注入架构**：子进程严格采用操作系统底层 `argv: [String]` 原生参数数组，原生兼容中文、空格与特殊字符，杜绝任何 Shell 拼接注入风险。
- **全格式开箱即用**：深度整合系统自带底层 `/usr/bin/zip`、`/usr/bin/tar` (bsdtar) 及 `/usr/bin/hdiutil`，免去复杂的环境配置。

---

## 📊 支持格式矩阵

| 格式 | 压缩打包 | 提取解压 | 密码保护 | 分卷压缩 | 压缩级别调节 | 底层实现 |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **ZIP** | ✅ | ✅ | ✅ (AES/标准) | ✅ | ✅ (0~9 级) | 系统原生 `/usr/bin/zip`, `/usr/bin/unzip` |
| **TAR** | ✅ | ✅ | ❌ | ❌ | ❌ | 系统原生 `/usr/bin/tar` (bsdtar) |
| **TAR.GZ** | ✅ | ✅ | ❌ | ❌ | ✅ (0~9 级) | 系统自带 bsdtar (内建 zlib) |
| **TAR.BZ2** | ✅ | ✅ | ❌ | ❌ | ✅ (0~9 级) | 系统自带 bsdtar (内建 bz2lib) |
| **TAR.XZ** | ✅ | ✅ | ❌ | ❌ | ✅ (0~9 级) | 系统自带 bsdtar (内建 liblzma) |
| **7-Zip (.7z)** | ✅* | ✅ | ✅ | ✅ | ✅ (0~9 级) | 7-Zip (安装 sevenzip 后自动激活) |
| **DMG / ISO** | ❌ (镜像) | ✅ | ❌ | ❌ | ❌ | 系统 `/usr/bin/hdiutil` 只读安全挂载提取 |
| **RAR / CAB / LZH** | ❌* | ✅* | ✅ | ❌ | ❌ | 支持通过 unar / 7zz / bsdtar 提取解压 |

> **说明**：RAR 压缩为闭源商业专利格式，市面主流 macOS 工具（如 Keka、The Unarchiver）均只提供 RAR 解压。本工具提供开箱即用的高兼容解压能力，若需高压缩比分卷打包，建议使用通用的 7-Zip 或 ZIP。

---

## 🚀 下载与安装

### 方式 1：直接下载发布包 (推荐)
前往 **[Releases 页面](https://github.com/qiao1225/macCompress/releases)** 下载最新构建的 `macCompress.dmg` 或 `macCompress-v1.0.0.zip`，解压后拖拽至 `应用程序 (Applications)` 文件夹即可运行。

### 方式 2：源码编译安装
要求：macOS 13+，Xcode 15+ 或 Swift 5.9+ 工具链。
```bash
# 克隆仓库
git clone https://github.com/qiao1225/macCompress.git
cd macCompress

# 编译并打包为原生 .app
./bundle_app.sh

# 安装到本机 Applications 目录
cp -R macCompress.app /Applications/
```

---

## 🖥 系统级深度集成

### 1. 访达右键菜单“快速操作”一键压缩
在终端中执行仓库自带的免签名安装脚本：
```bash
./Extensions/QuickActions/install_quick_action.sh
```
安装后，在访达中选中任意文件或文件夹，点击 **右键 → 快速操作 →【用 macCompress 压缩】**，即可瞬间唤醒应用并自动填入文件列表！

### 2. Dock 图标拖拽响应
直接将访达中的任意文件拖拽投递到屏幕下方 Dock 栏的 `macCompress` 图标上，应用将自动在前台展开并就绪。

---

## ☕️ 赞赏与支持

如果您觉得 **macCompress** 提升了您的 macOS 使用效率或对您的项目开发有所帮助，欢迎请作者喝杯咖啡！您的支持是开源持续迭代的最大动力 ❤️

<p align="center">
  <img src="assets/donate/qrcode_1.png" width="220" alt="赞赏码 1" />
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/donate/qrcode_2.png" width="220" alt="赞赏码 2" />
</p>

<p align="center">
  <em>扫描上方二维码，支持独立开发者的持续创作与优化</em>
</p>

---

## 📄 开源许可证

本项目基于 [MIT License](LICENSE) 许可证开源，欢迎提交 Issue 或 Pull Request！
