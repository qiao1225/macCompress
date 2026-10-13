//
//  FileListView.swift
//  macCompress
//
//  职责：已添加待压缩文件列表视图，展示系统原生图标、文件名、大小、移除操作与批量统计。
//

import SwiftUI
import AppKit

public struct FileListView: View {
    @ObservedObject var viewModel: MainViewModel

    private var totalBytes: Int64 {
        viewModel.items.reduce(0) { $0 + $1.fileSize }
    }

    private var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 列表工具栏
            HStack {
                Label("\(viewModel.items.count) 个项目（总计 \(formattedTotalSize)）", systemImage: "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    viewModel.presentFilePicker()
                }) {
                    Label("继续添加", systemImage: "plus")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)

                Divider()
                    .frame(height: 12)

                Button(action: {
                    viewModel.clearAllItems()
                }) {
                    Label("清空列表", systemImage: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // 明确的完成提示横幅（解决卡在95%疑惑，提供清晰完成反馈）
            if case .completed(_, let msg) = viewModel.status {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("🎉 压缩打包已完美完成！文件：\(msg)")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("在访达中定位") {
                        viewModel.revealLastOutputInFinder()
                    }
                    .controlSize(.small)

                    Button("清空并开始新任务") {
                        viewModel.clearCompression()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.12))

                Divider()
            }

            // 列表内容
            List(selection: $viewModel.selectedItemIDs) {
                ForEach(viewModel.items) { item in
                    HStack(spacing: 12) {
                        AppKitIconView(image: item.systemIcon, size: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Text(item.url.deletingLastPathComponent().path)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.head)
                        }

                        Spacer()

                        Text(item.formattedSize)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)

                        Button(action: {
                            viewModel.removeItem(id: item.id)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        .help("移除此项")
                    }
                    .padding(.vertical, 4)
                    .tag(item.id)
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }
}
