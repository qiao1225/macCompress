//
//  FileDropZoneView.swift
//  macCompress
//
//  职责：统一现代美学拖拽区，去掉常驻虚线框，采用柔和分区底色（12px 圆角），悬停整区高亮反馈与单一核心 CTA。
//

import SwiftUI
import UniformTypeIdentifiers

public struct FileDropZoneView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        VStack(spacing: 20) {
            // 中心圆角渐变图标与柔和微晕
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

                ModernIconView(
                    .archiveBox,
                    customSize: 34,
                    style: .primaryGradient
                )
                .scaleEffect(viewModel.isDropTargeted ? 1.12 : 1.0)
                .animation(ThemeTokens.Motion.springSnappy, value: viewModel.isDropTargeted)
            }

            // 描述文本
            VStack(spacing: 6) {
                Text(viewModel.isDropTargeted ? "松开鼠标立即添加文件" : "拖拽文件或文件夹至此")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)

                Text("支持同时批量拖入多个项目，智能匹配最佳压缩算法")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appTextSecondary)
            }

            // 唯一核心 CTA 按钮
            Button(action: {
                viewModel.presentFilePicker()
            }) {
                HStack(spacing: 6) {
                    ModernIconView(.folder, size: .sm, style: .monochrome(.white))
                    Text("浏览并选取文件...")
                }
            }
            .buttonStyle(PrimaryGradientButtonStyle(size: .regular))

            // 格式小标签 (统一紫色阶，无多余灰色)
            HStack(spacing: 6) {
                formatTag("ZIP")
                formatTag("7Z")
                formatTag("TAR.GZ")
                formatTag("DMG")
                formatTag("RAR")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
        // 柔和的分区底色与单层 12px 圆角（彻底移除常驻虚线噪音）
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
}
