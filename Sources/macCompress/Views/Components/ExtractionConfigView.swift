//
//  ExtractionConfigView.swift
//  macCompress
//
//  职责：解压提取模式视图，展示待解压归档包信息、解压命名为……、同名冲突处理、解压选项与完成后的清空/新任务流。
//

import SwiftUI
import AppKit

public struct ExtractionConfigView: View {
    @ObservedObject var viewModel: MainViewModel

    public var body: some View {
        VStack(spacing: 20) {
            if let archiveURL = viewModel.archiveToExtract {
                // 已选归档卡片
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        Image(systemName: ArchiveFormat.detect(from: archiveURL)?.iconName ?? "doc.zipper")
                            .font(.system(size: 38))
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(archiveURL.lastPathComponent)
                                .font(.system(size: 15, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Text(archiveURL.deletingLastPathComponent().path)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            Button("更换文件...") {
                                presentArchivePicker()
                            }
                            .controlSize(.small)

                            Button("清空") {
                                viewModel.clearExtraction()
                            }
                            .controlSize(.small)
                            .foregroundColor(.red.opacity(0.85))
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))

                    // 完成后高亮卡片与快捷操作（解决卡在95%与明确完成提示）
                    if case .completed(_, let msg) = viewModel.status {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("🎉 解压完成！已保存至：\(msg)")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text("您可以直接在访达中查看解压出的文件夹，或清空开始新任务")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button("在访达中显示") {
                                viewModel.revealLastOutputInFinder()
                            }
                            .controlSize(.regular)

                            Button("完成并清空") {
                                viewModel.clearExtraction()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.12)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.green.opacity(0.35), lineWidth: 1)
                        )
                    }

                    // 解压选项设置
                    VStack(alignment: .leading, spacing: 12) {
                        // 1. 解压命名为……（新增用户需求）
                        HStack {
                            Text("解压文件夹命名为：")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            TextField("默认与压缩包同名", text: $viewModel.extractionOptions.customFolderName)
                                .textFieldStyle(.roundedBorder)

                            if !viewModel.extractionOptions.customFolderName.isEmpty {
                                Button("重置") {
                                    viewModel.extractionOptions.customFolderName = ""
                                }
                                .font(.system(size: 11))
                                .buttonStyle(.borderless)
                                .foregroundColor(.secondary)
                            }
                        }

                        // 2. 同名文件夹冲突处理策略（新增用户需求）
                        HStack {
                            Text("遇同名文件夹时：")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

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

                        Toggle("在解压目标位置自动创建文件夹（避免文件散落）", isOn: $viewModel.extractionOptions.createSubfolder)
                            .font(.system(size: 12))

                        Toggle("解压完成后在访达 (Finder) 中高亮打开", isOn: $viewModel.extractionOptions.revealInFinderWhenFinished)
                            .font(.system(size: 12))

                        HStack {
                            Text("保存目录：")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Text(viewModel.extractionOptions.destinationDirectory?.path ?? "压缩包同级目录")
                                .font(.system(size: 12))
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            Button("更改...") {
                                viewModel.presentOutputDirectoryPicker()
                            }
                            .controlSize(.small)
                        }

                        // 密码输入框
                        HStack {
                            Text("解压密码（若有）：")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            SecureField("未加密可留空", text: Binding(
                                get: { viewModel.extractionOptions.password ?? "" },
                                set: { viewModel.extractionOptions.password = $0.isEmpty ? nil : $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor).opacity(0.5)))
                }
                .padding(20)
            } else {
                // 拖拽解压引导区
                VStack(spacing: 16) {
                    Image(systemName: "archivebox.and.arrow.down.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.accentColor.opacity(0.8))

                    Text("拖入需要解压的压缩包文件")
                        .font(.system(size: 16, weight: .semibold))

                    Text("支持 ZIP, 7Z, TAR, GZ, BZ2, XZ, RAR, DMG, ISO 等全格式")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    Button("选择压缩包...") {
                        presentArchivePicker()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
