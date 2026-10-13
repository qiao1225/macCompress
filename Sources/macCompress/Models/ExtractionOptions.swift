//
//  ExtractionOptions.swift
//  macCompress
//
//  职责：封装解压操作的参数配置（解压目录、自定义解压文件夹名称、同名冲突策略、是否创建专属子文件夹、密码等）。
//

import Foundation

/// 同名文件夹冲突处理策略
public enum NameCollisionStrategy: String, CaseIterable, Identifiable {
    case rename = "自动改名并保留两者"
    case overwrite = "替换覆盖已有文件夹"
    case ask = "遇到同名时提示我"

    public var id: String { rawValue }
}

public struct ExtractionOptions: Equatable {
    /// 目标解压路径，若为 nil 则默认解压到压缩包同级目录
    public var destinationDirectory: URL? = nil

    /// 自定义解压文件夹名称（若为空则默认使用压缩包文件名）
    public var customFolderName: String = ""

    /// 是否在目标目录下自动创建一个文件夹解压（防止文件散落）
    public var createSubfolder: Bool = true

    /// 遇同名文件夹冲突策略
    public var collisionStrategy: NameCollisionStrategy = .rename

    /// 解压完成后是否在访达 (Finder) 中高亮定位
    public var revealInFinderWhenFinished: Bool = true

    /// 是否覆盖已有文件
    public var overwriteExisting: Bool = false

    /// 解压密码（若压缩包有密码保护）
    public var password: String? = nil

    public init(
        destinationDirectory: URL? = nil,
        customFolderName: String = "",
        createSubfolder: Bool = true,
        collisionStrategy: NameCollisionStrategy = .rename,
        revealInFinderWhenFinished: Bool = true,
        overwriteExisting: Bool = false,
        password: String? = nil
    ) {
        self.destinationDirectory = destinationDirectory
        self.customFolderName = customFolderName
        self.createSubfolder = createSubfolder
        self.collisionStrategy = collisionStrategy
        self.revealInFinderWhenFinished = revealInFinderWhenFinished
        self.overwriteExisting = overwriteExisting
        self.password = password
    }
}
