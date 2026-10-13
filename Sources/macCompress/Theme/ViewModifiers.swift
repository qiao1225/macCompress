//
//  ViewModifiers.swift
//  macCompress
//
//  职责：统一现代卡片与按钮样式，严格遵循 12px 卡片与 8px 控件圆角规范。
//

import SwiftUI

// MARK: - 现代卡片修饰器 (统一 12px 圆角)

public struct ModernCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    public var cornerRadius: CGFloat = ThemeTokens.Radius.card
    public var padding: CGFloat = ThemeTokens.Spacing.lg

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.appCardBg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.appBorderSubtle, lineWidth: 1)
            )
    }
}

// MARK: - 主操作渐变按钮样式 (统一 8px 圆角)

public struct PrimaryGradientButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    @State private var isHovered = false
    public var size: ControlSize = .regular

    public init(size: ControlSize = .regular) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let horizontalPadding: CGFloat = size == .small ? 12 : 18
        let verticalPadding: CGFloat = size == .small ? 6 : 9
        let fontSize: CGFloat = size == .small ? 12 : 13
        let radius: CGFloat = ThemeTokens.Radius.control

        return configuration.label
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        isEnabled
                            ? (isHovered ? ColorTokens.Gradients.primaryButtonHover : ColorTokens.Gradients.primaryButton)
                            : LinearGradient(colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.white.opacity(isEnabled ? 0.2 : 0.05), lineWidth: 1)
            )
            .shadow(
                color: isEnabled
                    ? (isHovered ? ThemeTokens.Shadow.primaryButtonHover().color : ThemeTokens.Shadow.primaryButton().color)
                    : Color.clear,
                radius: isHovered ? 10 : 6,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .offset(y: (isHovered && isEnabled && !isPressed) ? -1 : 0)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(ThemeTokens.Motion.hoverLift, value: isHovered)
            .animation(ThemeTokens.Motion.fast, value: isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - 次级幽灵按钮样式 (统一 8px 圆角，统一紫色阶)

public struct SecondaryGhostButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    public var size: ControlSize = .regular

    public init(size: ControlSize = .regular) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        let horizontalPadding: CGFloat = size == .small ? 10 : 14
        let verticalPadding: CGFloat = size == .small ? 5 : 7
        let fontSize: CGFloat = size == .small ? 11 : 12
        let radius: CGFloat = ThemeTokens.Radius.control

        return configuration.label
            .font(.system(size: fontSize, weight: .medium))
            .foregroundColor(isHovered ? ColorTokens.Purple.p400 : Color.appTextSecondary)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(
                        isHovered
                            ? (colorScheme == .dark ? ColorTokens.Purple.p900.opacity(0.35) : ColorTokens.Purple.p100.opacity(0.6))
                            : Color.clear
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        isHovered ? ColorTokens.Purple.p500.opacity(0.4) : Color.appBorder.opacity(0.6),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(ThemeTokens.Motion.fast, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - 悬停轻微上浮

public struct HoverLiftModifier: ViewModifier {
    @State private var isHovered = false

    public func body(content: Content) -> some View {
        content
            .offset(y: isHovered ? -1 : 0)
            .animation(ThemeTokens.Motion.hoverLift, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - View 扩展方法

public extension View {
    func modernCard(
        cornerRadius: CGFloat = ThemeTokens.Radius.card,
        padding: CGFloat = ThemeTokens.Spacing.lg
    ) -> some View {
        self.modifier(ModernCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func hoverLift() -> some View {
        self.modifier(HoverLiftModifier())
    }
}
