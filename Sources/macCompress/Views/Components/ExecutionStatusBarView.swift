//
//  ExecutionStatusBarView.swift
//  macCompress
//
//  职责：底部状态与动作条，统一承载任务执行进度、状态反馈信息、取消按钮与一键压缩/解压主触发按钮。
//

import SwiftUI

public struct ExecutionStatusBarView: View {
    @ObservedObject var viewModel: MainViewModel

    public var body: some View {
        VStack(spacing: 8) {
            Divider()

            HStack(spacing: 14) {
                // 左侧：状态或进度展示
                VStack(alignment: .leading, spacing: 4) {
                    switch viewModel.status {
                    case .idle:
                        Text(viewModel.activeTab == .compress ? "已准备就绪，配置完成后点击右侧开始压缩" : "已准备就绪，点击右侧开始解压")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                    case .preparing(let desc):
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.small)
                            Text(desc)
                                .font(.system(size: 12))
                                .foregroundColor(.primary)
                        }

                    case .running(let progress, let currentItem, _, _):
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("正在处理：\(currentItem)")
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.accentColor)
                            }

                            ProgressView(value: progress)
                                .progressViewStyle(.linear)
                        }

                    case .completed(_, let msg):
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("已完成: \(msg)")
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Button("在访达中显示") {
                                viewModel.revealLastOutputInFinder()
                            }
                            .buttonStyle(.link)
                            .font(.system(size: 12))

                            Button("清空重置") {
                                viewModel.resetCurrentTab()
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                        }

                    case .failed(let msg):
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("失败: \(msg)")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                    case .cancelled:
                        HStack(spacing: 6) {
                            Image(systemName: "slash.circle")
                                .foregroundColor(.secondary)
                            Text("操作已取消")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // 右侧：取消按钮与执行主按钮
                HStack(spacing: 10) {
                    if viewModel.status.isBusy {
                        Button("取消") {
                            viewModel.cancelTask()
                        }
                        .controlSize(.regular)
                    }

                    if case .completed = viewModel.status {
                        Button(action: {
                            viewModel.resetCurrentTab()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                Text("完成并开始新任务")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    } else if viewModel.activeTab == .compress {
                        Button(action: {
                            viewModel.startCompress()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "archivebox.fill")
                                Text("一键压缩")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(viewModel.items.isEmpty || viewModel.status.isBusy)
                    } else {
                        Button(action: {
                            viewModel.startExtract()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc.fill")
                                Text("一键解压")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(viewModel.archiveToExtract == nil || viewModel.status.isBusy)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}
