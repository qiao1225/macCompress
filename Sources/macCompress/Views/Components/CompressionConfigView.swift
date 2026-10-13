//
//  CompressionConfigView.swift
//  macCompress
//
//  职责：参数配置面板（格式选择、命名、输出路径、预设/自定义压缩级别及详尽作用指南、密码加密、分卷说明）。
//

import SwiftUI

public struct CompressionConfigView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isShowingAdvanced: Bool = true
    @State private var isShowingLevelGuide: Bool = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. 格式选择与命名
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("目标格式")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

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
                    .frame(width: 170)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("归档包名称")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        TextField("压缩包名称", text: $viewModel.compressionOptions.customArchiveName)
                            .textFieldStyle(.roundedBorder)

                        Text(".\(viewModel.compressionOptions.format.fileExtension)")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }

            // 2. 输出位置设置
            VStack(alignment: .leading, spacing: 4) {
                Text("保存位置")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    Text(outputLocationDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("更改...") {
                        viewModel.presentOutputDirectoryPicker()
                    }
                    .controlSize(.small)

                    if viewModel.compressionOptions.customOutputDirectory != nil {
                        Button("重置") {
                            viewModel.compressionOptions.customOutputDirectory = nil
                        }
                        .controlSize(.small)
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor)))
            }

            Divider()

            // 3. 压缩级别调节与详尽指南（重点改造）
            if viewModel.compressionOptions.format.supportsCompressionLevel {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("压缩级别")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Button(action: {
                            isShowingLevelGuide.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("查看压缩级别作用与选择指南")

                        Spacer()

                        Text(compressionLevelText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)

                        if viewModel.compressionOptions.compressionLevel != 6 {
                            Button("恢复默认 (6级)") {
                                viewModel.compressionOptions.compressionLevel = 6
                            }
                            .font(.system(size: 10))
                            .buttonStyle(.link)
                        }
                    }

                    // 快速档位胶囊按钮组
                    HStack(spacing: 6) {
                        levelButton(title: "0 仅存储", level: 0)
                        levelButton(title: "3 快速", level: 3)
                        levelButton(title: "6 标准平衡 (默认)", level: 6)
                        levelButton(title: "9 极限压缩", level: 9)
                    }

                    // 连续滑块
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.compressionOptions.compressionLevel) },
                            set: { viewModel.compressionOptions.compressionLevel = Int($0) }
                        ),
                        in: 0...9,
                        step: 1
                    )

                    // 压缩级别作用说明卡片
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("级别作用与耗时说明：")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.primary)
                        }

                        Text("• 0 级 (仅存储)：不压缩体积，直接瞬间打包，最省 CPU。适合视频、音频、照片等已压缩格式；\n• 6 级 (推荐默认)：速度与体积最佳平衡点，适合绝大多数日常文件与文档打包；\n• 9 级 (极限深度)：体积最小但 CPU 运算时间最长，适合长久归档或需上传限额网盘的文本与工程。")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.controlBackgroundColor).opacity(0.6)))
                }
            }

            Divider()

            // 4. 高级选项折叠栏
            DisclosureGroup("高级选项（密码加密、分卷、过滤冗余文件）", isExpanded: $isShowingAdvanced) {
                VStack(alignment: .leading, spacing: 10) {
                    // 密码加密
                    if viewModel.compressionOptions.format.supportsPassword {
                        Toggle("启用密码加密保护", isOn: $viewModel.compressionOptions.isPasswordProtected)
                            .font(.system(size: 12))

                        if viewModel.compressionOptions.isPasswordProtected {
                            SecureField("输入加密密码", text: $viewModel.compressionOptions.password)
                                .textFieldStyle(.roundedBorder)
                                .padding(.leading, 20)
                        }
                    } else {
                        Text("当前格式 (\(viewModel.compressionOptions.format.shortName)) 不支持密码加密")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    // 分卷压缩
                    if viewModel.compressionOptions.format.supportsSplitVolume {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("分卷打包：")
                                    .font(.system(size: 12))
                                Picker("分卷大小", selection: $viewModel.compressionOptions.splitVolumeSize) {
                                    ForEach(SplitVolumeSize.allCases) { size in
                                        Text(size.title).tag(size)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }

                            if viewModel.compressionOptions.splitVolumeSize != .disabled {
                                Text("💡 分卷适用于将大文件切分为指定大小，方便邮件附件、FAT32 U盘或网盘传输")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // 排除 Mac 系统冗余隐藏文件
                    Toggle("排除 macOS 隐藏文件 (.DS_Store、__MACOSX、._*)", isOn: $viewModel.compressionOptions.excludeSystemMetadata)
                        .font(.system(size: 12))
                        .help("去除 Windows/Linux 解压时常见的 .DS_Store 与 __MACOSX 冗余文件夹")
                }
                .padding(.top, 6)
            }
            .font(.system(size: 12, weight: .medium))
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private func levelButton(title: String, level: Int) -> some View {
        let isSelected = viewModel.compressionOptions.compressionLevel == level
        Button(action: {
            viewModel.compressionOptions.compressionLevel = level
        }) {
            Text(title)
                .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.08))
                )
                .foregroundColor(isSelected ? .accentColor : .primary)
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
        case 0: return "仅存储 (不压缩，秒级打包)"
        case 1...3: return "快速压缩 (\(level) 级)"
        case 4...6: return "标准平衡 (\(level) 级) [推荐默认]"
        case 7...8: return "深度压缩 (\(level) 级)"
        case 9: return "极限最小 (\(level) 级)"
        default: return "\(level) 级"
        }
    }
}
