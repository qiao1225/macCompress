//
//  ColorTokens.swift
//  macCompress
//
//  职责：统一现代 Design Tokens 配色系统，确立以紫色（Purple Spectrum）为唯一品牌主色的 10 档色阶体系。
//

import SwiftUI
import AppKit

public struct ColorTokens {
    // MARK: - 核心品牌主色阶 (Purple 50 -> 950)
    
    public struct Purple {
        public static let p50  = Color(hex: "#F5F3FF") // 极浅紫 (亮色微背景/微浮层)
        public static let p100 = Color(hex: "#EDE9FE") // 次浅紫 (亮色选中底色/胶囊背景)
        public static let p200 = Color(hex: "#DDD6FE") // 浅紫边框/浅色描边
        public static let p300 = Color(hex: "#C4B5FD") // 次高光文本/图标渐变端
        public static let p400 = Color(hex: "#A78BFA") // 柔和微光/次级高亮
        public static let p500 = Color(hex: "#8B5CF6") // 核心品牌主色 (Primary Accent)
        public static let p600 = Color(hex: "#7C3AED") // 交互高亮态/深紫端点
        public static let p700 = Color(hex: "#6D28D9") // 强调态
        public static let p800 = Color(hex: "#5B21B6") // 暗色次级背景微衬
        public static let p900 = Color(hex: "#4C1D95") // 暗色深层强调
        public static let p950 = Color(hex: "#1E1235") // 暗色极深背景层
    }

    // 快捷别名 (保持向后兼容)
    public static let indigoPrimary = Purple.p600
    public static let violetPrimary = Purple.p500
    public static let violetLight   = Purple.p400

    // MARK: - 语义色 (Semantic Colors - WCAG AA 达标)
    
    public struct Semantic {
        // 成功 - 翡翠绿 (仅用于状态反馈)
        public static let successLight   = Color(hex: "#059669")
        public static let successDark    = Color(hex: "#34D399")
        public static let successBgLight = Color(hex: "#D1FAE5")
        public static let successBgDark  = Color(hex: "#064E3B").opacity(0.4)

        // 警告 - 琥珀金 (仅用于警告提示)
        public static let warningLight   = Color(hex: "#D97706")
        public static let warningDark    = Color(hex: "#FBBF24")
        public static let warningBgLight = Color(hex: "#FEF3C7")
        public static let warningBgDark  = Color(hex: "#78350F").opacity(0.4)

        // 错误 - 玫瑰红 (仅用于失败报错)
        public static let errorLight     = Color(hex: "#DC2626")
        public static let errorDark      = Color(hex: "#F87171")
        public static let errorBgLight   = Color(hex: "#FEE2E2")
        public static let errorBgDark    = Color(hex: "#7F1D1D").opacity(0.4)

        // 信息 - 天蓝
        public static let infoLight      = Color(hex: "#0284C7")
        public static let infoDark       = Color(hex: "#38BDF8")
    }

    // MARK: - 统一渐变规范 (统一从品牌紫色阶衍生)
    
    public struct Gradients {
        /// 主操作 CTA 渐变：Purple 600 -> Purple 500
        public static let primaryButton = LinearGradient(
            colors: [Purple.p600, Purple.p500],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 主操作 CTA 悬停渐变
        public static let primaryButtonHover = LinearGradient(
            colors: [Color(hex: "#8B5CF6"), Color(hex: "#9F75FF")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 图标圆角渐变填充：Purple 400 -> Purple 600
        public static let iconGradient = LinearGradient(
            colors: [Purple.p400, Purple.p600],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 拖拽区悬停高亮底色微晕
        public static let dropZoneHover = LinearGradient(
            colors: [Purple.p500.opacity(0.12), Purple.p600.opacity(0.06)],
            startPoint: .top,
            endPoint: .bottom
        )

        /// 进度条流光渐变
        public static let progressBar = LinearGradient(
            colors: [Purple.p600, Purple.p400],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - 动态环境自适应扩展

public extension Color {
    /// 构造 Hex 颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// 动态双主题色助手：基于系统 NSAppearance 动态产出
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        }))
    }

    // MARK: - 统一全局语义颜色（全部收敛至紫色阶与自适应灰阶）

    /// 应用背景色：带有微量紫色调的沉浸基底，消除刺眼全白或死灰
    static let appBackground = Color.dynamic(
        light: Color(hex: "#F9FAFC"),
        dark: Color(hex: "#0F111A")
    )

    /// 顶栏与浮层卡片表面色
    static let appSurface = Color.dynamic(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#151824")
    )

    /// 内部卡片与分区底色
    static let appCardBg = Color.dynamic(
        light: Color(hex: "#FFFFFF"),
        dark: Color(hex: "#181C2A")
    )

    /// 次级分区或内嵌区域
    static let appCardSecondaryBg = Color.dynamic(
        light: ColorTokens.Purple.p50.opacity(0.8),
        dark: Color(hex: "#1E2235")
    )

    /// 边框色（带有微弱紫色冷色感，避免脏灰）
    static let appBorder = Color.dynamic(
        light: Color(hex: "#E5E7EB"),
        dark: Color(hex: "#262C40")
    )

    /// 柔和高亮微边框
    static let appBorderSubtle = Color.dynamic(
        light: ColorTokens.Purple.p200.opacity(0.5),
        dark: ColorTokens.Purple.p500.opacity(0.2)
    )

    /// 主要文字
    static let appTextPrimary = Color.dynamic(
        light: Color(hex: "#111827"),
        dark: Color(hex: "#F9FAFB")
    )

    /// 次要文字
    static let appTextSecondary = Color.dynamic(
        light: Color(hex: "#4B5563"),
        dark: Color(hex: "#9CA3AF")
    )

    /// 辅助/占位文字
    static let appTextTertiary = Color.dynamic(
        light: Color(hex: "#9CA3AF"),
        dark: Color(hex: "#6B7280")
    )

    /// 品牌主交互色
    static let brandPrimary = ColorTokens.Purple.p500

    /// 品牌浅色交互背景 (选态、Tab、胶囊)
    static let brandSubtle = Color.dynamic(
        light: ColorTokens.Purple.p100,
        dark: ColorTokens.Purple.p900.opacity(0.4)
    )

    /// 语义：成功
    static let appSuccess = Color.dynamic(
        light: ColorTokens.Semantic.successLight,
        dark: ColorTokens.Semantic.successDark
    )
    static let appSuccessBg = Color.dynamic(
        light: ColorTokens.Semantic.successBgLight,
        dark: ColorTokens.Semantic.successBgDark
    )

    /// 语义：错误
    static let appError = Color.dynamic(
        light: ColorTokens.Semantic.errorLight,
        dark: ColorTokens.Semantic.errorDark
    )
    static let appErrorBg = Color.dynamic(
        light: ColorTokens.Semantic.errorBgLight,
        dark: ColorTokens.Semantic.errorBgDark
    )

    /// 语义：警告
    static let appWarning = Color.dynamic(
        light: ColorTokens.Semantic.warningLight,
        dark: ColorTokens.Semantic.warningDark
    )
    static let appWarningBg = Color.dynamic(
        light: ColorTokens.Semantic.warningBgLight,
        dark: ColorTokens.Semantic.warningBgDark
    )
}
