//
//  ThemeTokens.swift
//  macCompress
//
//  职责：圆角尺寸（12px 卡片 / 8px 控件）、阴影标尺、动画节奏与 4px 倍数间距体系。
//

import SwiftUI

public struct ThemeTokens {
    // MARK: - 统一圆角系统 (12px 卡片 / 8px 控件)
    
    public struct Radius {
        public static let badge: CGFloat = 4      // 状态标签
        public static let control: CGFloat = 8    // 控件/按钮/输入框
        public static let card: CGFloat = 12      // 分区/卡片
        public static let pill: CGFloat = 999     // 药丸胶囊

        // 兼容别名
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 8
        public static let lg: CGFloat = 12
        public static let xl: CGFloat = 12
    }

    // MARK: - 统一间距体系 (4px 基准倍数)
    
    public struct Spacing {
        public static let s4: CGFloat = 4
        public static let s8: CGFloat = 8
        public static let s12: CGFloat = 12
        public static let s16: CGFloat = 16
        public static let s20: CGFloat = 20
        public static let s24: CGFloat = 24
        public static let s32: CGFloat = 32

        // 兼容别名
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 32
    }

    // MARK: - 阴影与微光晕 (收敛到品牌紫色系)
    
    public struct Shadow {
        /// 主操作 CTA 按钮柔和阴影
        public static func primaryButton() -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            return (ColorTokens.Purple.p500.opacity(0.35), 8, 0, 3)
        }

        /// Hover 状态微光晕加深
        public static func primaryButtonHover() -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            return (ColorTokens.Purple.p500.opacity(0.50), 12, 0, 5)
        }
    }

    // MARK: - 动效节奏
    
    public struct Motion {
        public static let fast: Animation = .easeInOut(duration: 0.15)
        public static let pageTransition: Animation = .easeInOut(duration: 0.20)
        public static let springSnappy: Animation = .spring(response: 0.25, dampingFraction: 0.75)
        public static let hoverLift: Animation = .spring(response: 0.20, dampingFraction: 0.75)
    }
}
