//
//  ArchiveItem.swift
//  macCompress
//
//  职责：表示待压缩或正在处理的文件/文件夹项，封装文件元数据（大小、类型、系统原生图标、路径等）。
//

import Foundation
import AppKit

public struct ArchiveItem: Identifiable, Hashable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let fileSize: Int64
    public let formattedSize: String
    public let systemIcon: NSImage

    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = isDir.boolValue

        let calculatedSize = ArchiveItem.calculateSize(at: url, isDirectory: isDir.boolValue)
        self.fileSize = calculatedSize
        self.formattedSize = ByteCountFormatter.string(fromByteCount: calculatedSize, countStyle: .file)

        // 使用 NSWorkspace 获取 macOS 原生文件或文件夹图标
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)
        self.systemIcon = icon
    }

    public static func == (lhs: ArchiveItem, rhs: ArchiveItem) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// 计算文件或递归计算文件夹总大小
    private static func calculateSize(at url: URL, isDirectory: Bool) -> Int64 {
        if !isDirectory {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                return size
            }
            return 0
        }

        // 若为文件夹，快速统计直接子项及递归大小（为避免巨型目录阻塞，做安全递归）
        var totalSize: Int64 = 0
        let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey]
        if let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                   let isDir = resourceValues.isDirectory, !isDir,
                   let size = resourceValues.fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        return totalSize
    }
}
