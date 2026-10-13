//
//  MenuBarPopoverView.swift
//  macCompress
//
//  职责：常驻 macOS 菜单栏快捷面板，Marvis 现代美学圆角卡片、图标与快捷操作。
//

import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.colorScheme) var colorScheme

    public var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ModernIconView(.archiveBox, size: .sm, style: .primaryGradient)
                Text("macCompress 快捷归档")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)
                Spacer()
            }

            Divider()
                .overlay(Color.appBorderSubtle)

            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.items.isEmpty ? Color.appTextTertiary : ColorTokens.indigoPrimary)
                        .frame(width: 6, height: 6)

                    Text(viewModel.items.isEmpty ? "主窗口未添加文件" : "已就绪 \(viewModel.items.count) 个待压缩项目")
                        .font(.system(size: 12))
                        .foregroundColor(Color.appTextSecondary)
                }
                .padding(.vertical, 4)

                HStack(spacing: 10) {
                    Button("打开主窗口") {
                        NSApp.activate(ignoringOtherApps: true)
                        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                    .buttonStyle(PrimaryGradientButtonStyle(size: .small))

                    Button("退出应用") {
                        NSApp.terminate(nil)
                    }
                    .buttonStyle(SecondaryGhostButtonStyle(size: .small))
                }
            }
        }
        .padding(14)
        .frame(width: 250)
        .background(Color.appBackground)
    }
}
