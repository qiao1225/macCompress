//
//  CompressionConfigView.swift
//  macCompress
//
//  职责：Marvis 现代美学参数配置面板，分组卡片化、4档智能压缩级别、密码与分卷高级选项折叠。
//

import SwiftUI

public struct CompressionConfigView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isShowingAdvanced: Bool = true
    @State private var isShowingLevelGuide: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. 目标格式与命名大卡片
            formatAndNameCard

            // 2. 保存位置卡片
            outputLocationCard

            // 3. 压缩级别调节面板
            if viewModel.compressionOptions.format.supportsCompressionLevel {
                compressionLevelCard
            }

            // 4. 高级选项折叠卡片（密码、分卷、过滤隐藏文件）
            advancedOptionsCard

            // 5. 主区域核心 CTA：立即开始压缩打包按钮
            Button(action: {
                viewModel.startCompress()
            }) {
                HStack(spacing: 8) {
                    ModernIconView(.archiveBox, size: .sm, style: .monochrome(.white))
                    Text("立即开始压缩打包")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryGradientButtonStyle(size: .regular))
            .disabled(viewModel.items.isEmpty || viewModel.status.isBusy)
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.appBackground)
    }

    // MARK: - 1. 格式与命名卡片

    private var formatAndNameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ModernIconView(.archiveBox, size: .sm, style: .monochrome(ColorTokens.indigoPrimary))
                Text("目标格式与归档命名")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)
            }

            HStack(spacing: 12) {
                // 格式选择
                VStack(alignment: .leading, spacing: 4) {
                    Text("打包格式")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.appTextSecondary)

                    Picker("格式", selection: $viewModel.compressionOptions.format) {
                        ForEach(ArchiveFormat.allCases.filter { $0.supportsCompression }) { fmt in
                            HStack {
                                Image(systemName: fmt.iconName)
                                Text(fmt.displayName)
                            }
                            .tag(fmt)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 155)
                }

                // 命名输入框
                VStack(alignment: .leading, spacing: 4) {
                    Text("归档包名称")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.appTextSecondary)

                    HStack(spacing: 6) {
                        TextField("压缩包名称", text: $viewModel.compressionOptions.customArchiveName)
                            .textFieldStyle(.roundedBorder)

                        Text(".\(viewModel.compressionOptions.format.fileExtension)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(ColorTokens.indigoPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(ColorTokens.indigoPrimary.opacity(0.12))
                            )
                    }
                }
            }
        }
        .modernCard(cornerRadius: ThemeTokens.Radius.md, padding: 12)
    }

    // MARK: - 2. 保存位置卡片

    private var outputLocationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ModernIconView(.folder, size: .sm, style: .monochrome(ColorTokens.violetPrimary))
                Text("保存目标目录")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)
            }

            HStack(spacing: 10) {
                Text(outputLocationDescription)
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button("更改目录...") {
                    viewModel.presentOutputDirectoryPicker()
                }
                .buttonStyle(SecondaryGhostButtonStyle(size: .small))

                if viewModel.compressionOptions.customOutputDirectory != nil {
                    Button("重置") {
                        viewModel.compressionOptions.customOutputDirectory = nil
                    }
                    .buttonStyle(SecondaryGhostButtonStyle(size: .small))
                    .foregroundColor(Color.appTextTertiary)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.sm)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
            )
        }
        .modernCard(cornerRadius: ThemeTokens.Radius.md, padding: 12)
    }

    // MARK: - 3. 压缩级别面板

    private var compressionLevelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ModernIconView(.settings, size: .sm, style: .monochrome(ColorTokens.indigoPrimary))
                Text("压缩算法强度")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)

                Spacer()

                Text(compressionLevelText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ColorTokens.indigoPrimary)

                if viewModel.compressionOptions.compressionLevel != 6 {
                    Button("恢复标准 (6级)") {
                        withAnimation(ThemeTokens.Motion.fast) {
                            viewModel.compressionOptions.compressionLevel = 6
                        }
                    }
                    .font(.system(size: 10))
                    .buttonStyle(.link)
                }
            }

            // 4 档智能胶囊切换器 (Marvis 现代交互)
            HStack(spacing: 6) {
                levelButton(title: "0 仅存储", level: 0)
                levelButton(title: "3 快速", level: 3)
                levelButton(title: "6 标准平衡 (默认)", level: 6)
                levelButton(title: "9 极限压缩", level: 9)
            }

            // 精准连续滑块
            Slider(
                value: Binding(
                    get: { Double(viewModel.compressionOptions.compressionLevel) },
                    set: { viewModel.compressionOptions.compressionLevel = Int($0) }
                ),
                in: 0...9,
                step: 1
            )
            .accentColor(ColorTokens.indigoPrimary)

            // 说明微卡片
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(ColorTokens.violetPrimary)
                    Text("智能调节建议：")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                }

                Text("• 0 级 (秒速打包)：不耗 CPU，仅聚合文件，最适合视频、照片、音频等已压缩文件\n• 6 级 (推荐平衡)：最佳耗时与体积平衡点，兼顾传输效率与速度\n• 9 级 (极限深度)：最极致压缩率，适合云盘归档与大工程代码备份")
                    .font(.system(size: 10))
                    .foregroundColor(Color.appTextSecondary)
                    .lineSpacing(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.sm)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
            )
        }
        .modernCard(cornerRadius: ThemeTokens.Radius.md, padding: 12)
    }

    // MARK: - 4. 高级选项折叠卡片

    private var advancedOptionsCard: some View {
        DisclosureGroup(isExpanded: $isShowingAdvanced) {
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                    .overlay(Color.appBorderSubtle)

                // 密码加密
                if viewModel.compressionOptions.format.supportsPassword {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            ModernIconView(.lockSecurity, size: .sm, style: .monochrome(viewModel.compressionOptions.isPasswordProtected ? ColorTokens.indigoPrimary : Color.appTextTertiary))
                            Toggle("启用密码加密保护", isOn: $viewModel.compressionOptions.isPasswordProtected)
                                .font(.system(size: 12, weight: .medium))
                        }

                        if viewModel.compressionOptions.isPasswordProtected {
                            SecureField("输入加密保护密码", text: $viewModel.compressionOptions.password)
                                .textFieldStyle(.roundedBorder)
                                .padding(.leading, 24)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        ModernIconView(.lockSecurity, size: .sm, style: .monochrome(Color.appTextTertiary))
                        Text("当前格式 (\(viewModel.compressionOptions.format.shortName)) 不支持密码加密")
                            .font(.system(size: 11))
                            .foregroundColor(Color.appTextTertiary)
                    }
                }

                // 分卷打包
                if viewModel.compressionOptions.format.supportsSplitVolume {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            ModernIconView(.splitVolume, size: .sm, style: .monochrome(ColorTokens.violetPrimary))
                            Text("分卷打包：")
                                .font(.system(size: 12, weight: .medium))

                            Picker("分卷大小", selection: $viewModel.compressionOptions.splitVolumeSize) {
                                ForEach(SplitVolumeSize.allCases) { size in
                                    Text(size.title).tag(size)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }

                        if viewModel.compressionOptions.splitVolumeSize != .disabled {
                            Text("💡 自动按切片大小分块存储，便于网络传输与邮件附件分发")
                                .font(.system(size: 10))
                                .foregroundColor(Color.appTextSecondary)
                                .padding(.leading, 24)
                        }
                    }
                }

                // 排除 macOS 隐藏文件
                Toggle("排除 macOS 隐藏文件 (.DS_Store、__MACOSX、._*)", isOn: $viewModel.compressionOptions.excludeSystemMetadata)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextPrimary)
                    .help("去除在 Windows/Linux 解压时多出的冗余元数据垃圾文件")
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.2.square")
                    .font(.system(size: 12))
                    .foregroundColor(ColorTokens.indigoPrimary)
                Text("高级选项（密码加密、分卷、过滤冗余元数据）")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.appTextPrimary)
            }
        }
        .modernCard(cornerRadius: ThemeTokens.Radius.md, padding: 12)
    }

    // MARK: - 辅助组件

    @ViewBuilder
    private func levelButton(title: String, level: Int) -> some View {
        let isSelected = viewModel.compressionOptions.compressionLevel == level
        Button(action: {
            withAnimation(ThemeTokens.Motion.fast) {
                viewModel.compressionOptions.compressionLevel = level
            }
        }) {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: ThemeTokens.Radius.sm)
                        .fill(isSelected ? ColorTokens.indigoPrimary.opacity(0.18) : (colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.03)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeTokens.Radius.sm)
                        .strokeBorder(isSelected ? ColorTokens.indigoPrimary.opacity(0.6) : Color.clear, lineWidth: 1)
                )
                .foregroundColor(isSelected ? ColorTokens.indigoPrimary : Color.appTextSecondary)
        }
        .buttonStyle(.plain)
    }

    private var outputLocationDescription: String {
        if let custom = viewModel.compressionOptions.customOutputDirectory {
            return custom.path
        }
        if let first = viewModel.items.first {
            return "与源文件同目录 (\(first.url.deletingLastPathComponent().lastPathComponent))"
        }
        return "与源文件同目录"
    }

    private var compressionLevelText: String {
        let level = viewModel.compressionOptions.compressionLevel
        switch level {
        case 0: return "0级 仅存储 (不压缩/秒出)"
        case 1...3: return "\(level)级 快速压缩"
        case 4...6: return "\(level)级 标准平衡 (推荐)"
        case 7...8: return "\(level)级 深度压缩"
        case 9: return "9级 极限最小体积"
        default: return "\(level) 级"
        }
    }
}
