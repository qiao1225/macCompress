//
//  ArchiveFormat.swift
//  macCompress
//
//  职责：定义支持的归档/压缩格式枚举，管理每种格式的特性能力（密码、分卷、级别等）与扩展名映射。
//

import Foundation

/// 归档格式枚举
public enum ArchiveFormat: String, CaseIterable, Identifiable, Codable {
    case zip = "zip"
    case tar = "tar"
    case tarGz = "tar.gz"
    case tarBz2 = "tar.bz2"
    case tarXz = "tar.xz"
    case sevenZip = "7z"
    case rar = "rar"
    case dmg = "dmg"
    case iso = "iso"

    public var id: String { rawValue }

    /// 显示名称
    public var displayName: String {
        switch self {
        case .zip: return "ZIP (.zip)"
        case .tar: return "TAR (.tar)"
        case .tarGz: return "GZIP (.tar.gz)"
        case .tarBz2: return "BZIP2 (.tar.bz2)"
        case .tarXz: return "XZ (.tar.xz)"
        case .sevenZip: return "7-Zip (.7z)"
        case .rar: return "RAR (.rar)"
        case .dmg: return "Apple 磁盘镜像 (.dmg)"
        case .iso: return "光盘镜像 (.iso)"
        }
    }

    /// 简短名称
    public var shortName: String {
        switch self {
        case .zip: return "ZIP"
        case .tar: return "TAR"
        case .tarGz: return "TAR.GZ"
        case .tarBz2: return "TAR.BZ2"
        case .tarXz: return "TAR.XZ"
        case .sevenZip: return "7Z"
        case .rar: return "RAR"
        case .dmg: return "DMG"
        case .iso: return "ISO"
        }
    }

    /// 默认文件后缀名
    public var fileExtension: String {
        switch self {
        case .zip: return "zip"
        case .tar: return "tar"
        case .tarGz: return "tar.gz"
        case .tarBz2: return "tar.bz2"
        case .tarXz: return "tar.xz"
        case .sevenZip: return "7z"
        case .rar: return "rar"
        case .dmg: return "dmg"
        case .iso: return "iso"
        }
    }

    /// 是否支持压缩（打包生成）
    public var supportsCompression: Bool {
        switch self {
        case .zip, .tar, .tarGz, .tarBz2, .tarXz, .sevenZip:
            return true
        case .rar, .dmg, .iso:
            return false // rar 系统无开源原生压缩器；dmg/iso 解压专用
        }
    }

    /// 是否支持解压
    public var supportsExtraction: Bool {
        return true
    }

    /// 是否支持密码保护加密
    public var supportsPassword: Bool {
        switch self {
        case .zip, .sevenZip:
            return true
        default:
            return false
        }
    }

    /// 是否支持分卷压缩
    public var supportsSplitVolume: Bool {
        switch self {
        case .zip, .sevenZip:
            return true
        default:
            return false
        }
    }

    /// 是否支持调节压缩级别 (0-9)
    public var supportsCompressionLevel: Bool {
        switch self {
        case .zip, .tarGz, .tarBz2, .tarXz, .sevenZip:
            return true
        case .tar, .rar, .dmg, .iso:
            return false
        }
    }

    /// 对应的 SF Symbol 图标名称
    public var iconName: String {
        switch self {
        case .zip: return "doc.zipper"
        case .tar, .tarGz, .tarBz2, .tarXz: return "archivebox"
        case .sevenZip: return "shippingbox"
        case .rar: return "doc.badge.gearshape"
        case .dmg: return "internaldrive"
        case .iso: return "opticaldisc"
        }
    }

    /// 根据文件扩展名识别对应的格式
    public static func detect(from url: URL) -> ArchiveFormat? {
        let filename = url.lastPathComponent.lowercased()
        if filename.hasSuffix(".tar.gz") || filename.hasSuffix(".tgz") {
            return .tarGz
        }
        if filename.hasSuffix(".tar.bz2") || filename.hasSuffix(".tbz2") {
            return .tarBz2
        }
        if filename.hasSuffix(".tar.xz") || filename.hasSuffix(".txz") {
            return .tarXz
        }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "zip": return .zip
        case "tar": return .tar
        case "gz": return .tarGz
        case "bz2": return .tarBz2
        case "xz": return .tarXz
        case "7z": return .sevenZip
        case "rar": return .rar
        case "dmg": return .dmg
        case "iso": return .iso
        default: return nil
        }
    }
}
