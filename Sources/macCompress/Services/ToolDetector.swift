//
//  ToolDetector.swift
//  macCompress
//
//  职责：负责检测系统自带与环境中的命令行工具（zip, bsdtar, hdiutil, 7z/7zz, unar 等），提供路径缓存与能力状态判断。
//

import Foundation

public enum KnownTool: String, CaseIterable {
    case zip = "zip"
    case tar = "tar"
    case unzip = "unzip"
    case hdiutil = "hdiutil"
    case sevenZip = "7zz"
    case unar = "unar"
    case unrar = "unrar"
}

public final class ToolDetector {
    public static let shared = ToolDetector()

    private var cachedPaths: [KnownTool: URL] = [:]
    private let fileManager = FileManager.default

    private init() {
        refreshToolPaths()
    }

    /// 刷新并扫描工具路径
    public func refreshToolPaths() {
        cachedPaths.removeAll()

        // 默认扫描的系统与常见包管理器路径（Apple Silicon / Intel Homebrew）
        let searchDirectories = [
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin",
            "/opt/homebrew/bin",
            "/usr/local/bin"
        ]

        // 1. zip
        cachedPaths[.zip] = locateExecutable(names: ["zip"], in: searchDirectories)
        // 2. tar (bsdtar)
        cachedPaths[.tar] = locateExecutable(names: ["tar", "bsdtar"], in: searchDirectories)
        // 3. unzip
        cachedPaths[.unzip] = locateExecutable(names: ["unzip"], in: searchDirectories)
        // 4. hdiutil (DMG/ISO 挂载专用)
        cachedPaths[.hdiutil] = locateExecutable(names: ["hdiutil"], in: ["/usr/bin", "/bin"])
        // 5. 7z (支持 7zz, 7z, 7za)
        cachedPaths[.sevenZip] = locateExecutable(names: ["7zz", "7z", "7za"], in: searchDirectories)
        // 6. unar (The Unarchiver 命令行工具，解压 rar/冷门格式利器)
        cachedPaths[.unar] = locateExecutable(names: ["unar"], in: searchDirectories)
        // 7. unrar
        cachedPaths[.unrar] = locateExecutable(names: ["unrar"], in: searchDirectories)
    }

    /// 获取工具的实际可执行文件路径
    public func executableURL(for tool: KnownTool) -> URL? {
        return cachedPaths[tool]
    }

    /// 检查 7-Zip 是否已就绪
    public var is7zAvailable: Bool {
        return cachedPaths[.sevenZip] != nil
    }

    /// 检查 unar 是否可用
    public var isUnarAvailable: Bool {
        return cachedPaths[.unar] != nil
    }

    /// 检查 RAR 解压是否支持（unar / unrar / 7z 任一可用即可）
    public var isRarExtractionSupported: Bool {
        return cachedPaths[.unar] != nil || cachedPaths[.unrar] != nil || cachedPaths[.sevenZip] != nil
    }

    /// 内部查找逻辑：按候选文件名与候选目录按序匹配，检查是否具备执行权限
    private func locateExecutable(names: [String], in directories: [String]) -> URL? {
        for dir in directories {
            for name in names {
                let candidatePath = (dir as NSString).appendingPathComponent(name)
                if fileManager.isExecutableFile(atPath: candidatePath) {
                    return URL(fileURLWithPath: candidatePath)
                }
            }
        }
        return nil
    }
}
