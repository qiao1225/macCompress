//
//  ExtractionConfigView.swift
//  macCompress
//
//  职责：统一现代美学解压模式视图，无虚线分区底色、单一核心 CTA、主色阶闭环。
//

import SwiftUI
import AppKit

public struct ExtractionConfigView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        VStack(spacing: 0) {
            if let archiveURL = viewModel.archiveToExtract {
                // 已选归档配置流
                ScrollView {
                    VStack(spacing: 12) {
                        // 1. 已选归档文件卡片
                        selectedArchiveCard(url: archiveURL)

                        // 2. 解压完成横幅与快捷操作
                        if case .completed(_, let msg) = viewModel.status {
                            completionSuccessCard(msg: msg)
                        }

                        // 3. 解压高级参数设置面板
                        extractionSettingsCard

                        // 4. 主区域核心 CTA：立即提取解压按钮
                        Button(action: {
                            viewModel.startExtract()
                        }) {
                            HStack(spacing: 8) {
                                ModernIconView(.extract, size: .sm, style: .monochrome(.white))
                                Text("立即开始提取解压")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryGradientButtonStyle(size: .regular))
                        .disabled(viewModel.status.isBusy)
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            } else {
                // 空状态拖拽解压引导区（无常驻虚线，单一核心 CTA）
                emptyDropZone
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }

    // MARK: - 空状态大卡片 (柔和分区底色，去除常驻虚线噪声)

    private var emptyDropZone: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        viewModel.isDropTargeted
                            ? ColorTokens.Purple.p500.opacity(0.18)
                            : (colorScheme == .dark ? ColorTokens.Purple.p900.opacity(0.2) : ColorTokens.Purple.p100.opacity(0.5))
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                viewModel.isDropTargeted ? ColorTokens.Purple.p500 : Color.appBorderSubtle,
                                lineWidth: 1.5
                            )
                    )

                ModernIconView(.extract, customSize: 36, style: .primaryGradient)
                    .scaleEffect(viewModel.isDropTargeted ? 1.12 : 1.0)
                    .animation(ThemeTokens.Motion.springSnappy, value: viewModel.isDropTargeted)
            }

            VStack(spacing: 6) {
                Text(viewModel.isDropTargeted ? "松开鼠标立即载入压缩包" : "拖入需要解压的压缩包文件")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)

                Text("支持 ZIP, 7Z, TAR, GZ, BZ2, XZ, RAR, DMG, ISO 等全格式生态")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextSecondary)
            }

            // 唯一核心 CTA 按钮
            Button(action: {
                presentArchivePicker()
            }) {
                HStack(spacing: 6) {
                    ModernIconView(.extract, size: .sm, style: .monochrome(.white))
                    Text("选择压缩包...")
                }
            }
            .buttonStyle(PrimaryGradientButtonStyle(size: .regular))

            // 格式标签 (统一紫色阶)
            HStack(spacing: 6) {
                formatTag("ZIP")
                formatTag("7-ZIP")
                formatTag("TAR.GZ")
                formatTag("RAR")
                formatTag("DMG 镜像")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: ThemeTokens.Radius.card, style: .continuous)
                .fill(
                    viewModel.isDropTargeted
                        ? ColorTokens.Purple.p500.opacity(colorScheme == .dark ? 0.14 : 0.08)
                        : Color.appCardSecondaryBg
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThemeTokens.Radius.card, style: .continuous)
                .strokeBorder(
                    viewModel.isDropTargeted
                        ? ColorTokens.Purple.p500
                        : Color.appBorderSubtle,
                    lineWidth: viewModel.isDropTargeted ? 2.0 : 1.0
                )
        )
        .padding(16)
        .animation(ThemeTokens.Motion.fast, value: viewModel.isDropTargeted)
    }

    // MARK: - 1. 已选归档卡片

    private func selectedArchiveCard(url: URL) -> some View {
        HStack(spacing: 12) {
            ModernIconView(.archiveBox, customSize: 30, style: .primaryGradient)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(url.deletingLastPathComponent().path)
                    .font(.system(size: 10))
                    .foregroundColor(Color.appTextTertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer()

            HStack(spacing: 6) {
                Button("更换文件...") {
                    presentArchivePicker()
                }
                .buttonStyle(SecondaryGhostButtonStyle(size: .small))

                Button("清空") {
                    viewModel.clearExtraction()
                }
                .buttonStyle(SecondaryGhostButtonStyle(size: .small))
                .foregroundColor(ColorTokens.Semantic.errorLight)
            }
        }
        .modernCard(cornerRadius: ThemeTokens.Radius.card, padding: 12)
    }

    // MARK: - 2. 解压完成横幅

    private func completionSuccessCard(msg: String) -> some View {
        HStack(spacing: 12) {
            ModernIconView(.statusSuccess, size: .md, style: .semanticSuccess)

            VStack(alignment: .leading, spacing: 2) {
                Text("解压提取已顺利完成！")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.appSuccess)

                Text(msg)
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("在访达中显示") {
                viewModel.revealLastOutputInFinder()
            }
            .buttonStyle(SecondaryGhostButtonStyle(size: .small))

            Button("提取新文件") {
                viewModel.clearExtraction()
            }
            .buttonStyle(PrimaryGradientButtonStyle(size: .small))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: ThemeTokens.Radius.card)
                .fill(Color.appSuccessBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThemeTokens.Radius.card)
                .strokeBorder(Color.appSuccess.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - 3. 参数配置卡片

    private var extractionSettingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ModernIconView(.settings, size: .sm, style: .monochrome(ColorTokens.Purple.p400))
                Text("解压输出配置")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)
            }

            // 解压命名
            HStack(spacing: 8) {
                Text("解压文件夹命名：")
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextSecondary)

                TextField("默认与压缩包同名", text: $viewModel.extractionOptions.customFolderName)
                    .textFieldStyle(.roundedBorder)

                if !viewModel.extractionOptions.customFolderName.isEmpty {
                    Button("重置") {
                        viewModel.extractionOptions.customFolderName = ""
                    }
                    .buttonStyle(SecondaryGhostButtonStyle(size: .small))
                }
            }

            // 同名冲突策略
            HStack(spacing: 8) {
                Text("遇同名文件策略：")
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextSecondary)

                Picker("同名处理", selection: $viewModel.extractionOptions.collisionStrategy) {
                    ForEach(NameCollisionStrategy.allCases) { strategy in
                        Text(strategy.rawValue).tag(strategy)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                Spacer()
            }

            Divider()
                .overlay(Color.appBorderSubtle)

            Toggle("自动创建解压子文件夹（避免文件散落）", isOn: $viewModel.extractionOptions.createSubfolder)
                .font(.system(size: 11))
                .foregroundColor(Color.appTextPrimary)

            Toggle("解压完成后在访达 (Finder) 中高亮打开", isOn: $viewModel.extractionOptions.revealInFinderWhenFinished)
                .font(.system(size: 11))
                .foregroundColor(Color.appTextPrimary)

            // 目标路径
            HStack(spacing: 8) {
                Text("保存目标目录：")
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextSecondary)

                Text(viewModel.extractionOptions.destinationDirectory?.path ?? "压缩包同级目录")
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button("更改目录...") {
                    viewModel.presentOutputDirectoryPicker()
                }
                .buttonStyle(SecondaryGhostButtonStyle(size: .small))
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.control)
                    .fill(Color.appCardSecondaryBg)
            )

            // 密码输入框
            HStack(spacing: 8) {
                ModernIconView(.lockSecurity, size: .sm, style: .monochrome(ColorTokens.Purple.p400))
                Text("解压密码（若有）：")
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextSecondary)

                SecureField("未加密可留空", text: Binding(
                    get: { viewModel.extractionOptions.password ?? "" },
                    set: { viewModel.extractionOptions.password = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
        .modernCard(cornerRadius: ThemeTokens.Radius.card, padding: 12)
    }

    @ViewBuilder
    private func formatTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(ColorTokens.Purple.p400)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.badge)
                    .fill(colorScheme == .dark ? ColorTokens.Purple.p900.opacity(0.3) : ColorTokens.Purple.p100.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.badge)
                    .strokeBorder(ColorTokens.Purple.p500.opacity(0.2), lineWidth: 0.8)
            )
    }

    private func presentArchivePicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.prompt = "选择解压文件"

        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            viewModel.archiveToExtract = selectedURL
            viewModel.extractionOptions.customFolderName = selectedURL.deletingPathExtension().lastPathComponent
            viewModel.status = .idle
        }
    }
}
