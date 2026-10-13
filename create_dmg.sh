#!/usr/bin/env bash
#
# create_dmg.sh
# 职责：将打包好的 macCompress.app 打包为 DMG 安装镜像与 macOS 标准 ZIP 归档包
#
set -euo pipefail

APP_NAME="macCompress"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
ZIP_NAME="${APP_NAME}-v${VERSION}-macOS.zip"

echo "==> 1. 确保最新应用包构建..."
./bundle_app.sh

echo "==> 2. 准备 DMG 挂载暂存区..."
rm -rf dmg_staging
mkdir -p dmg_staging
cp -R "${APP_NAME}.app" dmg_staging/
ln -s /Applications dmg_staging/Applications

echo "==> 3. 生成 DMG 安装包: $DMG_NAME..."
rm -f "$DMG_NAME"
hdiutil create -volname "${APP_NAME}" -srcfolder dmg_staging -ov -format UDZO "$DMG_NAME"
rm -rf dmg_staging

echo "==> 4. 生成 ZIP 绿色包: $ZIP_NAME..."
rm -f "$ZIP_NAME"
ditto -c -k --keepParent "${APP_NAME}.app" "$ZIP_NAME"

echo "==> ✅ 成功生成发布资产:"
ls -lh "$DMG_NAME" "$ZIP_NAME"
