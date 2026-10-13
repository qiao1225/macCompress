//
//  CompressionEngine.swift
//  macCompress
//
//  职责：统一压缩调度引擎，根据用户配置组装对应工具（zip、bsdtar、7z）的原生命令行参数，
//       精确统计总文件数并计算活百分比进度、中途取消清理半成品临时文件机制。
//

import Foundation

public final class CompressionEngine {
    private let processRunner = ProcessRunner()
    private let toolDetector = ToolDetector.shared

    public init() {}

    /// 执行压缩任务
    /// - Parameters:
    ///   - items: 待压缩的文件/目录列表
    ///   - options: 压缩参数配置
    ///   - progressHandler: 进度回调 (进度 0.0~1.0, 当前说明)
    /// - Returns: 生成的目标归档文件 URL
    public func compress(
        items: [ArchiveItem],
        options: CompressionOptions,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> URL {
        guard !items.isEmpty else {
            throw CompressionError.emptyInputFiles
        }

        // 1. 参数合法性校验
        if case .failure(let error) = options.validate() {
            throw error
        }

        // 2. 计算输出路径与工作目录
        let (outputURL, workingDirectory, relativeItemPaths) = try preparePaths(items: items, options: options)

        // 3. 统计真实总文件数量以驱动活百分比
        let totalFiles = countTotalFiles(in: items)

        progressHandler(0.01, "正在分析文件列表 (共 \(totalFiles) 个文件)...")

        do {
            // 4. 根据所选格式分发调用
            switch options.format {
            case .zip:
                try await runZipCompression(
                    relativePaths: relativeItemPaths,
                    outputURL: outputURL,
                    workingDirectory: workingDirectory,
                    totalFiles: totalFiles,
                    options: options,
                    progressHandler: progressHandler
                )

            case .tar, .tarGz, .tarBz2, .tarXz:
                try await runTarCompression(
                    relativePaths: relativeItemPaths,
                    outputURL: outputURL,
                    workingDirectory: workingDirectory,
                    totalFiles: totalFiles,
                    options: options,
                    progressHandler: progressHandler
                )

            case .sevenZip:
                try await runSevenZipCompression(
                    relativePaths: relativeItemPaths,
                    outputURL: outputURL,
                    workingDirectory: workingDirectory,
                    totalFiles: totalFiles,
                    options: options,
                    progressHandler: progressHandler
                )

            case .rar, .dmg, .iso:
                throw CompressionError.unsupportedFeature("\(options.format.displayName) 暂不支持作为生成格式（仅支持解压）")
            }

            // 5. 验证产物完整性
            guard FileManager.default.fileExists(atPath: outputURL.path) || options.splitVolumeSize != .disabled else {
                throw CompressionError.executionFailed("归档完成但未检测到生成的输出文件")
            }

            progressHandler(1.0, "压缩完成！已成功打包 \(totalFiles) 个文件")
            return outputURL
        } catch {
            // 6. 中途取消或异常失败保护机制：清理写入一半的不完整文件，避免桌面留下损坏文件
            cleanupIncompleteFiles(outputURL: outputURL)
            throw error
        }
    }

    /// 取消正在执行的任务
    public func cancel() {
        processRunner.cancel()
    }

    /// 清理未完成的半成品临时文件
    private func cleanupIncompleteFiles(outputURL: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            try? fileManager.removeItem(at: outputURL)
        }

        // 若有分卷文件（如 name.z01, name.z02, name.zip），一并扫描清理
        let dir = outputURL.deletingLastPathComponent()
        let baseName = outputURL.deletingPathExtension().lastPathComponent
        if let entries = try? fileManager.contentsOfDirectory(atPath: dir.path) {
            for entry in entries where entry.hasPrefix(baseName) {
                let fullPath = dir.appendingPathComponent(entry)
                try? fileManager.removeItem(at: fullPath)
            }
        }
    }

    /// 真实统计所有待压缩项目中的正规文件总数
    private func countTotalFiles(in items: [ArchiveItem]) -> Int {
        var count = 0
        let fileManager = FileManager.default

        for item in items {
            if item.isDirectory {
                if let enumerator = fileManager.enumerator(
                    at: item.url,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) {
                    for case let fileURL as URL in enumerator {
                        if let values = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                           values.isRegularFile == true {
                            count += 1
                        }
                    }
                }
            } else {
                count += 1
            }
        }
        return max(count, 1)
    }

    // MARK: - 内部执行逻辑：ZIP (系统原生 /usr/bin/zip)

    private func runZipCompression(
        relativePaths: [String],
        outputURL: URL,
        workingDirectory: URL,
        totalFiles: Int,
        options: CompressionOptions,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        guard let zipBin = toolDetector.executableURL(for: .zip) else {
            throw CompressionError.missingExecutable("zip (/usr/bin/zip)")
        }

        var args: [String] = []
        // 递归打包
        args.append("-r")

        // 压缩级别 -0 ~ -9
        let level = min(max(options.compressionLevel, 0), 9)
        args.append("-\(level)")

        // 密码加密
        if options.isPasswordProtected && !options.password.isEmpty {
            args.append("-P")
            args.append(options.password)
        }

        // 分卷压缩 (如 -s 100m)
        if options.splitVolumeSize != .disabled {
            args.append("-s")
            args.append("\(options.splitVolumeSize.rawValue)m")
        }

        // 输出目标路径 (必须是绝对路径或从工作目录解析的路径)
        args.append(outputURL.path)

        // 追加待打包文件名
        args.append(contentsOf: relativePaths)

        // 排除 macOS 冗余系统文件（注意：/usr/bin/zip 要求 -x 必须位于待打包文件列表之后）
        if options.excludeSystemMetadata {
            args.append("-x")
            args.append("*.DS_Store")
            args.append("-x")
            args.append("*__MACOSX*")
            args.append("-x")
            args.append("*/._*")
        }

        var processedCounter = 0

        try await processRunner.run(
            executableURL: zipBin,
            arguments: args,
            currentDirectoryURL: workingDirectory
        ) { line in
            // 解析 zip 命令的标准输出例如 "adding: xxx (deflated 60%)"
            if line.contains("adding:") {
                processedCounter += 1
                // 活百分比动态计算：根据真实已处理文件数与总文件数严格推导
                let ratio = min(max(Double(processedCounter) / Double(totalFiles), 0.02), 0.99)
                let itemDesc = line.components(separatedBy: "adding:").last?.trimmingCharacters(in: .whitespaces) ?? ""
                progressHandler(ratio, "(\(processedCounter)/\(totalFiles)) \(itemDesc)")
            }
        }
    }

    // MARK: - 内部执行逻辑：TAR / GZ / BZ2 / XZ (系统原生 bsdtar)

    private func runTarCompression(
        relativePaths: [String],
        outputURL: URL,
        workingDirectory: URL,
        totalFiles: Int,
        options: CompressionOptions,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        guard let tarBin = toolDetector.executableURL(for: .tar) else {
            throw CompressionError.missingExecutable("tar (/usr/bin/tar)")
        }

        var args: [String] = []

        // 根据格式指定标志
        switch options.format {
        case .tar:
            args.append("-cf")
        case .tarGz:
            args.append("-czf")
        case .tarBz2:
            args.append("-cjf")
        case .tarXz:
            args.append("-cJf")
        default:
            args.append("-cf")
        }

        args.append(outputURL.path)

        // 排除 macOS 系统文件
        if options.excludeSystemMetadata {
            args.append("--exclude=.DS_Store")
            args.append("--exclude=._*")
        }

        // 详细输出以便追踪进度
        args.append("-v")

        // 待压缩文件
        args.append(contentsOf: relativePaths)

        var processed = 0

        try await processRunner.run(
            executableURL: tarBin,
            arguments: args,
            currentDirectoryURL: workingDirectory
        ) { line in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !trimmed.hasPrefix("tar:") {
                processed += 1
                let ratio = min(max(Double(processed) / Double(totalFiles), 0.02), 0.99)
                progressHandler(ratio, "(\(processed)/\(totalFiles)) \(trimmed)")
            }
        }
    }

    // MARK: - 内部执行逻辑：7-Zip (7zz / 7z)

    private func runSevenZipCompression(
        relativePaths: [String],
        outputURL: URL,
        workingDirectory: URL,
        totalFiles: Int,
        options: CompressionOptions,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        guard let sevenZipBin = toolDetector.executableURL(for: .sevenZip) else {
            throw CompressionError.missingExecutable("7-Zip (7zz)。请在终端执行 'brew install sevenzip' 进行安装，或使用内置的 ZIP/TAR 格式。")
        }

        var args: [String] = ["a", outputURL.path]

        // 压缩级别
        let level = min(max(options.compressionLevel, 0), 9)
        args.append("-mx=\(level)")

        // 密码
        if options.isPasswordProtected && !options.password.isEmpty {
            args.append("-p\(options.password)")
            // 加密文件头，隐藏文件名
            args.append("-mhe=on")
        }

        // 分卷
        if options.splitVolumeSize != .disabled {
            args.append("-v\(options.splitVolumeSize.rawValue)m")
        }

        // 排除
        if options.excludeSystemMetadata {
            args.append("-xr!.DS_Store")
            args.append("-xr!__MACOSX")
        }

        args.append(contentsOf: relativePaths)

        try await processRunner.run(
            executableURL: sevenZipBin,
            arguments: args,
            currentDirectoryURL: workingDirectory
        ) { line in
            if line.contains("%") {
                let progressStr = line.trimmingCharacters(in: .whitespaces)
                progressHandler(0.5, progressStr)
            }
        }
    }

    // MARK: - 路径解析与安全命名

    private func preparePaths(
        items: [ArchiveItem],
        options: CompressionOptions
    ) throws -> (outputURL: URL, workingDirectory: URL, relativePaths: [String]) {
        let firstItemURL = items[0].url
        let parentDir = firstItemURL.deletingLastPathComponent()

        // 目标目录
        let targetDirectory = options.customOutputDirectory ?? parentDir

        // 目标文件名
        let baseName: String
        if !options.customArchiveName.trimmingCharacters(in: .whitespaces).isEmpty {
            baseName = options.customArchiveName.trimmingCharacters(in: .whitespaces)
        } else if items.count == 1 {
            let item = items[0]
            if item.isDirectory {
                baseName = item.name
            } else {
                baseName = item.url.deletingPathExtension().lastPathComponent
            }
        } else {
            baseName = "\(items[0].url.deletingPathExtension().lastPathComponent)_archive"
        }

        let fullFileName = "\(baseName).\(options.format.fileExtension)"
        let candidateOutputURL = targetDirectory.appendingPathComponent(fullFileName)

        // 检查并避免直接覆盖已有文件（自动追加递增后缀）
        let finalOutputURL = makeUniqueURL(targetURL: candidateOutputURL)

        // 相对路径解析：如果所有项都在同一父目录下，以该父目录为 workingDirectory
        let workingDir = parentDir
        let relativePaths = items.map { $0.url.lastPathComponent }

        return (finalOutputURL, workingDir, relativePaths)
    }

    private func makeUniqueURL(targetURL: URL) -> URL {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: targetURL.path) {
            return targetURL
        }

        let directory = targetURL.deletingLastPathComponent()
        let ext = targetURL.pathExtension
        let baseName = targetURL.deletingPathExtension().lastPathComponent

        var counter = 1
        while true {
            let newName = "\(baseName) (\(counter)).\(ext)"
            let newURL = directory.appendingPathComponent(newName)
            if !fileManager.fileExists(atPath: newURL.path) {
                return newURL
            }
            counter += 1
        }
    }
}
