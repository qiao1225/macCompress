//
//  CompressionOptions.swift
//  macCompress
//
//  职责：封装用户指定的压缩配置参数（格式、压缩级别、加密密码、分卷大小、过滤系统冗余文件等）。
//

import Foundation

/// 分卷预设大小枚举
public enum SplitVolumeSize: Int, CaseIterable, Identifiable {
    case disabled = 0
    case mb10 = 10
    case mb100 = 100
    case mb500 = 500
    case mb1024 = 1024
    case mb2048 = 2048

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .disabled: return "不分卷 (单个文件)"
        case .mb10: return "10 MB (邮件附件)"
        case .mb100: return "100 MB"
        case .mb500: return "500 MB"
        case .mb1024: return "1 GB (FAT32/U盘)"
        case .mb2048: return "2 GB (网盘单文件限制)"
        }
    }
}

/// 压缩参数配置模型
public struct CompressionOptions: Equatable {
    /// 目标压缩格式
    public var format: ArchiveFormat = .zip
    
    /// 压缩级别：0(仅存储) ~ 9(最大压缩极限)，默认为 6 (平衡)
    public var compressionLevel: Int = 6
    
    /// 是否开启密码加密
    public var isPasswordProtected: Bool = false
    
    /// 密码明文（仅在内存中暂存，执行完毕后置空）
    public var password: String = ""
    
    /// 分卷设置
    public var splitVolumeSize: SplitVolumeSize = .disabled
    
    /// 是否过滤 macOS 元数据与隐藏文件（如 .DS_Store, __MACOSX, ._*）
    public var excludeSystemMetadata: Bool = true
    
    /// 输出文件夹路径（若为 nil，则默认与首个待压缩文件同目录）
    public var customOutputDirectory: URL? = nil
    
    /// 自定义归档包文件名（不含扩展名），若为 nil 则取首个文件名称
    public var customArchiveName: String = ""

    public init(
        format: ArchiveFormat = .zip,
        compressionLevel: Int = 6,
        isPasswordProtected: Bool = false,
        password: String = "",
        splitVolumeSize: SplitVolumeSize = .disabled,
        excludeSystemMetadata: Bool = true,
        customOutputDirectory: URL? = nil,
        customArchiveName: String = ""
    ) {
        self.format = format
        self.compressionLevel = compressionLevel
        self.isPasswordProtected = isPasswordProtected
        self.password = password
        self.splitVolumeSize = splitVolumeSize
        self.excludeSystemMetadata = excludeSystemMetadata
        self.customOutputDirectory = customOutputDirectory
        self.customArchiveName = customArchiveName
    }

    /// 校验当前选项合法性
    public func validate() -> Result<Void, CompressionError> {
        if isPasswordProtected {
            guard format.supportsPassword else {
                return .failure(.unsupportedFeature("当前格式 \(format.shortName) 不支持设置加密密码"))
            }
            guard !password.isEmpty else {
                return .failure(.invalidParameter("已勾选密码保护，但密码不能为空"))
            }
        }
        if splitVolumeSize != .disabled {
            guard format.supportsSplitVolume else {
                return .failure(.unsupportedFeature("当前格式 \(format.shortName) 不支持分卷打包"))
            }
        }
        return .success(())
    }
}

/// 压缩相关错误类型
public enum CompressionError: LocalizedError, Equatable {
    case emptyInputFiles
    case invalidParameter(String)
    case unsupportedFeature(String)
    case missingExecutable(String)
    case executionFailed(String)
    case processCancelled
    case permissionDenied(String)
    case destinationAlreadyExists(String)

    public var errorDescription: String? {
        switch self {
        case .emptyInputFiles:
            return "未添加任何需要压缩的文件或文件夹"
        case .invalidParameter(let msg):
            return "参数无效：\(msg)"
        case .unsupportedFeature(let msg):
            return "功能不受支持：\(msg)"
        case .missingExecutable(let tool):
            return "系统缺少必要的可执行工具：\(tool)，请检查环境或安装依赖"
        case .executionFailed(let reason):
            return "压缩/解压命令执行失败：\(reason)"
        case .processCancelled:
            return "操作已由用户手动取消"
        case .permissionDenied(let path):
            return "没有访问或写入路径的权限：\(path)"
        case .destinationAlreadyExists(let path):
            return "目标文件已存在：\(path)"
        }
    }
}
