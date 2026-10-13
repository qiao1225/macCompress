//
//  SidebarView.swift
//  macCompress
//
//  职责：macOS 原生常驻左侧边栏，支持 Vibrancy 毛玻璃效果、固定宽 180px 常驻图文导航、应用名完整单行展示。
//

import SwiftUI
import AppKit

public struct SidebarView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isShowingFormatSheet: Bool = false
    @Environment(\.colorScheme) var colorScheme

    public static let sidebarWidth: CGFloat = 180

    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 顶部：红绿灯避让 + 品牌完整展示区
            headerBrandSection
                .padding(.top, 42) // 预留红绿灯垂直居中高度
                .padding(.bottom, 24)

            // 中间：核心功能导航 (常驻图文并茂，无收缩)
            VStack(spacing: 8) {
                navItem(
                    title: "压缩打包",
                    tab: .compress,
                    icon: .archiveBox
                )

                navItem(
                    title: "提取解压",
                    tab: .extract,
                    icon: .extract
                )
            }
            .padding(.horizontal, 12)

            Spacer()

            // 底部：全格式生态入口 (单一入口，常驻完整展示)
            VStack(spacing: 6) {
                Button(action: {
                    isShowingFormatSheet = true
                }) {
                    HStack(spacing: 8) {
                        ModernIconView(
                            .badgeSeal,
                            size: .sm,
                            style: .monochrome(ColorTokens.Purple.p400)
                        )

                        Text("全格式生态")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.appTextSecondary)
                            .lineLimit(1)

                        Spacer()
                    }
                }
                .buttonStyle(SidebarFormatButtonStyle())
                .popover(isPresented: $isShowingFormatSheet, arrowEdge: .trailing) {
                    formatOverviewSheet
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .frame(width: Self.sidebarWidth)
        .background(
            // macOS 原生 Vibrancy 毛玻璃底衬
            VibrancyBackground()
        )
        .overlay(
            // 右侧分割细描边
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.appBorderSubtle),
            alignment: .trailing
        )
    }

    // MARK: - 顶部品牌区域 (应用名单行完整显示，绝不换行)

    private var headerBrandSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("macCompress")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.appTextPrimary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Text("通用极速归档")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(ColorTokens.Purple.p400)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    // MARK: - 导航单项 (常驻图文并茂，左对齐)

    @ViewBuilder
    private func navItem(title: String, tab: AppTab, icon: ModernIconType) -> some View {
        let isSelected = viewModel.activeTab == tab

        Button(action: {
            withAnimation(ThemeTokens.Motion.fast) {
                viewModel.activeTab = tab
            }
        }) {
            HStack(spacing: 10) {
                ModernIconView(
                    icon,
                    size: .sm,
                    style: isSelected ? .monochrome(.white) : .monochrome(Color.appTextSecondary)
                )

                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : Color.appTextSecondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.control, style: .continuous)
                    .fill(
                        isSelected
                            ? ColorTokens.Gradients.primaryButton
                            : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(
                        color: isSelected ? ColorTokens.Purple.p500.opacity(0.35) : Color.clear,
                        radius: 5,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.control, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.white.opacity(0.25) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 全格式生态弹窗

    private var formatOverviewSheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ModernIconView(.badgeSeal, size: .md, style: .primaryGradient)
                Text("全格式生态覆盖与使用说明")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)
                Spacer()
            }

            Text("客户端内置极速解压与高效打包引擎，全格式原生兼容：")
                .font(.system(size: 11))
                .foregroundColor(Color.appTextSecondary)

            VStack(alignment: .leading, spacing: 6) {
                formatGuideRow(name: "ZIP", status: "压缩 & 解压", badge: "全平台通用", desc: "日常办公与网络传输首选，支持 AES 密码与分卷。")
                formatGuideRow(name: "7-Zip (.7z)", status: "压缩 & 解压", badge: "最高压缩比", desc: "高强度切片压缩，体积大幅精简。")
                formatGuideRow(name: "TAR 系列 (.tar.gz / .xz)", status: "压缩 & 解压", badge: "开发部署", desc: "Linux/服务器首选，完整保留文件权限元数据。")
                formatGuideRow(name: "DMG / ISO 镜像", status: "免刻录提取", badge: "磁盘镜像", desc: "只读安全挂载，直接提取 App 与安装镜像。")
                formatGuideRow(name: "RAR / CAB 等", status: "兼容提取", badge: "网络传统包", desc: "自动识别提取 Windows 传统常见格式。")
            }
        }
        .padding(16)
        .frame(width: 440)
        .background(Color.appCardBg)
    }

    @ViewBuilder
    private func formatGuideRow(name: String, status: String, badge: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.appTextPrimary)
                Text(status)
                    .font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.appSuccessBg)
                    .foregroundColor(Color.appSuccess)
                    .cornerRadius(3)
                Text(badge)
                    .font(.system(size: 9))
                    .foregroundColor(Color.appTextTertiary)
            }
            Text(desc)
                .font(.system(size: 10))
                .foregroundColor(Color.appTextSecondary)
        }
        .padding(4)
    }
}

// MARK: - 侧边栏底部生态按钮样式
public struct SidebarFormatButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 7)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.control, style: .continuous)
                    .fill(
                        isHovered
                            ? (colorScheme == .dark ? ColorTokens.Purple.p900.opacity(0.4) : ColorTokens.Purple.p100.opacity(0.7))
                            : Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: ThemeTokens.Radius.control, style: .continuous)
                    .strokeBorder(
                        isHovered
                            ? ColorTokens.Purple.p500.opacity(0.35)
                            : Color.appBorderSubtle.opacity(0.6),
                        lineWidth: 0.8
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(ThemeTokens.Motion.fast, value: isHovered)
            .onHover { isHovered = $0 }
    }
}

// MARK: - 原生 macOS 毛玻璃背景 (Vibrancy NSVisualEffectView)
public struct VibrancyBackground: NSViewRepresentable {
    public init() {}

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .sidebar
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
