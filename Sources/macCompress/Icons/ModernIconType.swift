//
//  ModernIconType.swift
//  macCompress
//
//  职责：统一现代图标类型、尺寸规范（16/20/24/32px）与着色模式定义。
//

import SwiftUI

/// 现代图标尺寸等级
public enum ModernIconSize: CGFloat {
    case sm = 16
    case md = 20
    case lg = 24
    case xl = 32
    
    public var pointSize: CGFloat { rawValue }
    
    /// 线宽规范 (1.5 - 2.0px)
    public var lineWidth: CGFloat {
        switch self {
        case .sm: return 1.5
        case .md: return 1.6
        case .lg: return 1.8
        case .xl: return 2.0
        }
    }
}

/// 现代图标着色模式
public enum ModernIconStyle {
    case monochrome(Color)
    case primaryGradient
    case accentGlow
    case dualTone(primary: Color, secondary: Color)
    case semanticSuccess
    case semanticWarning
    case semanticError
}

/// 现代核心图标集枚举 (不少于 12 个)
public enum ModernIconType: String, CaseIterable {
    case archiveBox      // 压缩包/归档
    case extract         // 解压/提取/展开
    case lockSecurity    // 加密/安全锁
    case splitVolume     // 分卷/切片
    case folder          // 文件夹
    case settings        // 设置/调节
    case compressing     // 压缩中/向心聚拢
    case statusSuccess   // 成功状态
    case statusWarning   // 警告状态
    case statusError     // 失败/错误状态
    case fileGeneric     // 通用文件/文档
    case previewEye      // 预览/查看
    case trashClean      // 清空/移除
    case finderReveal    // 访达定位/打开
    case badgeSeal       // 全生态支持勋章
}
