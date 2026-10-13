#!/usr/bin/env bash
#
# bundle_app.sh
# 职责：将编译出的可执行文件与 Info.plist 打包为标准的 macOS 原生 .app 应用包
#
set -euo pipefail

APP_NAME="macCompress"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "==> 1. 执行 Swift 发布构建..."
swift build -c release

echo "==> 2. 构建 .app Bundle 目录结构..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "==> 3. 拷贝可执行文件、图标与元数据..."
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi
for icon_png in AppIcon*.png MenuBarIcon*.png; do
    if [ -f "$icon_png" ]; then
        cp "$icon_png" "$APP_BUNDLE/Contents/Resources/"
    fi
done

# 赋予可执行权限
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "==> 4. 生成 PkgInfo..."
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "==> 5. 移除隔离属性并执行 adhoc 签名..."
xattr -cr "$APP_BUNDLE" || true
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> ✅ 成功生成 macOS 原生应用包: $(pwd)/$APP_BUNDLE"
echo "==> 您可以直接双击运行，或将其拖拽到 /Applications (应用程序) 目录中！"
