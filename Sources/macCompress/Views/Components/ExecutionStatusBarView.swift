//
//  ExecutionStatusBarView.swift
//  macCompress
//
//  职责：统一现代美学状态展示区，纯粹的【状态 + 进度】反馈，彻底移除分散的功能按钮。
//

import SwiftUI

public struct ExecutionStatusBarView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.appBorderSubtle)

            HStack(spacing: 16) {
                // 左侧：状态说明与语义指示灯
                statusContent
                    .frame(maxWidth: .infinity, alignment: .leading)

                // 右侧：仅在运行状态下展示实时进度条与取消按钮
                if case .running(let progress, _, _, _) = viewModel.status {
                    HStack(spacing: 12) {
                        ModernProgressBar(value: progress)
                            .frame(width: 140, height: 6)

                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(ColorTokens.Purple.p400)
                            .frame(width: 36, alignment: .trailing)

                        Button("取消") {
                            viewModel.cancelTask()
                        }
                        .buttonStyle(SecondaryGhostButtonStyle(size: .small))
                    }
                } else if case .completed = viewModel.status {
                    Button("在访达中定位") {
                        viewModel.revealLastOutputInFinder()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .buttonStyle(.link)
                    .foregroundColor(ColorTokens.Purple.p400)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.appSurface)
        }
    }

    // MARK: - 状态文案与语义指示

    @ViewBuilder
    private var statusContent: some View {
        switch viewModel.status {
        case .idle:
            HStack(spacing: 8) {
                Circle()
                    .fill(ColorTokens.Purple.p500.opacity(0.6))
                    .frame(width: 6, height: 6)

                Text(viewModel.activeTab == .compress
                     ? (viewModel.items.isEmpty ? "就绪：拖入文件或点击上方按钮开始" : "已就绪 \(viewModel.items.count) 个项目，点击右侧面板立即压缩")
                     : (viewModel.archiveToExtract == nil ? "就绪：拖入压缩包或点击上方按钮开始" : "已就绪归档包，点击下方按钮开始提取"))
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextSecondary)
            }

        case .preparing(let desc):
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(desc)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.appTextPrimary)
            }

        case .running(_, let currentItem, _, _):
            HStack(spacing: 8) {
                ModernIconView(.compressing, size: .sm, style: .primaryGradient)
                Text("正在处理：\(currentItem)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

        case .completed(_, let msg):
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ModernIconView(.statusSuccess, size: .sm, style: .semanticSuccess)
                    Text("完成")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.appSuccessBg)
                .foregroundColor(Color.appSuccess)
                .cornerRadius(ThemeTokens.Radius.badge)

                Text(msg)
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

        case .failed(let msg):
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    ModernIconView(.statusError, size: .sm, style: .semanticError)
                    Text("失败")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.appErrorBg)
                .foregroundColor(Color.appError)
                .cornerRadius(ThemeTokens.Radius.badge)

                Text(msg)
                    .font(.system(size: 11))
                    .foregroundColor(Color.appError)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

        case .cancelled:
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.appTextTertiary)
                    .frame(width: 6, height: 6)

                Text("任务已取消")
                    .font(.system(size: 11))
                    .foregroundColor(Color.appTextTertiary)
            }
        }
    }
}

// MARK: - 主色渐变平滑进度条

private struct ModernProgressBar: View {
    let value: Double
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(colorScheme == .dark ? ColorTokens.Purple.p900.opacity(0.4) : ColorTokens.Purple.p100)
                    .frame(height: geometry.size.height)

                Capsule()
                    .fill(ColorTokens.Gradients.progressBar)
                    .frame(width: max(0, min(CGFloat(value) * geometry.size.width, geometry.size.width)), height: geometry.size.height)
                    .shadow(color: ColorTokens.Purple.p500.opacity(0.4), radius: 3, x: 0, y: 1)
                    .animation(.easeInOut(duration: 0.2), value: value)
            }
        }
    }
}
