//
//  FileListView.swift
//  macCompress
//
//  职责：Marvis 现代美学已添加文件列表，现代表格卡片、行悬停浮动高亮、状态标签化与操作反馈。
//

import SwiftUI
import AppKit

public struct FileListView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.colorScheme) var colorScheme

    private var totalBytes: Int64 {
        viewModel.items.reduce(0) { $0 + $1.fileSize }
    }

    private var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 列表现代工具栏
            HStack(spacing: 12) {
                // 项目数量与总大小指示胶囊
                HStack(spacing: 6) {
                    ModernIconView(.fileGeneric, size: .sm, style: .primaryGradient)
                    Text("\(viewModel.items.count) 个项目")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.appTextPrimary)
                    Text("•")
                        .foregroundColor(ColorTokens.Purple.p400)
                    Text(formattedTotalSize)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(ColorTokens.Purple.p300)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? ColorTokens.Purple.p900.opacity(0.3) : ColorTokens.Purple.p100.opacity(0.6))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(ColorTokens.Purple.p500.opacity(0.2), lineWidth: 0.8)
                )

                Spacer()

                // 继续添加
                Button(action: {
                    viewModel.presentFilePicker()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text("继续添加")
                    }
                }
                .buttonStyle(SecondaryGhostButtonStyle(size: .small))

                // 清空全部
                Button(action: {
                    viewModel.clearAllItems()
                }) {
                    HStack(spacing: 4) {
                        ModernIconView(.trashClean, size: .sm, style: .monochrome(ColorTokens.Semantic.errorLight.opacity(0.85)))
                        Text("清空")
                    }
                }
                .buttonStyle(SecondaryGhostButtonStyle(size: .small))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appSurface)

            Divider()
                .overlay(Color.appBorder)

            // 完成状态卡片横幅 (Marvis 智能感知仪式感)
            if case .completed(_, let msg) = viewModel.status {
                HStack(spacing: 12) {
                    ModernIconView(.statusSuccess, size: .md, style: .semanticSuccess)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("压缩打包已完成！")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.appSuccess)
                        Text(msg)
                            .font(.system(size: 11))
                            .foregroundColor(Color.appTextSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Spacer()

                    Button(action: {
                        viewModel.revealLastOutputInFinder()
                    }) {
                        HStack(spacing: 4) {
                            ModernIconView(.finderReveal, size: .sm, style: .monochrome(Color.primary))
                            Text("在访达中定位")
                        }
                    }
                    .buttonStyle(SecondaryGhostButtonStyle(size: .small))

                    Button("新任务") {
                        viewModel.clearCompression()
                    }
                    .buttonStyle(PrimaryGradientButtonStyle(size: .small))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.appSuccessBg)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.appSuccess.opacity(0.3)),
                    alignment: .bottom
                )
            }

            // 现代卡片式行列表
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(viewModel.items) { item in
                        FileItemRow(
                            item: item,
                            isSelected: viewModel.selectedItemIDs.contains(item.id),
                            onDelete: {
                                withAnimation(ThemeTokens.Motion.fast) {
                                    viewModel.removeItem(id: item.id)
                                }
                            }
                        )
                    }
                }
                .padding(12)
            }
            .background(Color.appBackground)
        }
    }
}

// MARK: - 单行现代卡片视图

private struct FileItemRow: View {
    let item: ArchiveItem
    let isSelected: Bool
    let onDelete: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // 系统原生图标（带柔和圆角背景底衬）
            AppKitIconView(image: item.systemIcon, size: 28)
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.04) : Color.black.opacity(0.02))
                )

            // 文件名与路径层级
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.appTextPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(item.url.deletingLastPathComponent().path)
                    .font(.system(size: 10))
                    .foregroundColor(Color.appTextTertiary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer()

            // 文件大小标签 (等宽设计)
            Text(item.formattedSize)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color.appTextSecondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )

            // 删除操作微按钮 (Hover 浮现)
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isHovered ? ColorTokens.Semantic.errorLight : Color.appTextTertiary)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(isHovered ? ColorTokens.Semantic.errorLight.opacity(0.12) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help("移除此项")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: ThemeTokens.Radius.md, style: .continuous)
                .fill(
                    isHovered
                        ? (colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
                        : (colorScheme == .dark ? Color.white.opacity(0.02) : Color.white.opacity(0.6))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: ThemeTokens.Radius.md, style: .continuous)
                .strokeBorder(
                    isHovered
                        ? ColorTokens.indigoPrimary.opacity(0.3)
                        : Color.appBorderSubtle,
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(isHovered ? (colorScheme == .dark ? 0.3 : 0.05) : 0),
            radius: 4,
            x: 0,
            y: 2
        )
        .offset(y: isHovered ? -1 : 0)
        .animation(ThemeTokens.Motion.fast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
