//
//  ExtractionEngine.swift
//  macCompress
//
//  职责：统一解压调度引擎，支持 zip, tar 系列, 7z, rar, 以及 dmg/iso 挂载提取，
//       支持自定义解压文件夹名称、同名冲突（覆盖/改名）策略及中途取消清理半成品目录机制。
//

import Foundation

public final class ExtractionEngine {
    private let processRunner = ProcessRunner()
    private let toolDetector = ToolDetector.shared

    public init() {}

    /// 执行解压操作
    /// - Parameters:
    ///   - archiveURL: 压缩包路径
    ///   - options: 解压选项（目标目录、自定义解压名、同名冲突策略、密码等）
    ///   - progressHandler: 进度更新回调
    /// - Returns: 解压出的目标目录 URL
    public func extract(
        archiveURL: URL,
        options: ExtractionOptions,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> URL {
        guard FileManager.default.fileExists(atPath: archiveURL.path) else {
            throw CompressionError.executionFailed("归档文件不存在: \(archiveURL.path)")
        }

        // 识别格式
        guard let format = ArchiveFormat.detect(from: archiveURL) else {
            throw CompressionError.unsupportedFeature("未能识别该归档文件的格式: \(archiveURL.lastPathComponent)")
        }

        // 1. 确定解压文件夹名称（支持自定义名称）
        let baseDestination = options.destinationDirectory ?? archiveURL.deletingLastPathComponent()
        let rawFolderName: String
        if !options.customFolderName.trimmingCharacters(in: .whitespaces).isEmpty {
            rawFolderName = options.customFolderName.trimmingCharacters(in: .whitespaces)
        } else {
            var name = archiveURL.deletingPathExtension().lastPathComponent
            if name.hasSuffix(".tar") {
                name = (name as NSString).deletingPathExtension
            }
            rawFolderName = name
        }

        let targetCandidateURL: URL
        if options.createSubfolder {
            targetCandidateURL = baseDestination.appendingPathComponent(rawFolderName)
        } else {
            targetCandidateURL = baseDestination
        }

        // 2. 处理同名文件夹冲突策略（覆盖 / 自动重命名）
        let finalDestinationURL: URL
        let fileManager = FileManager.default

        if options.createSubfolder && fileManager.fileExists(atPath: targetCandidateURL.path) {
            switch options.collisionStrategy {
            case .rename, .ask:
                finalDestinationURL = makeUniqueDirectoryURL(targetURL: targetCandidateURL)
            case .overwrite:
                finalDestinationURL = targetCandidateURL
                try? fileManager.removeItem(at: finalDestinationURL)
            }
        } else {
            finalDestinationURL = targetCandidateURL
        }

        // 确保目标目录已创建
        try fileManager.createDirectory(at: finalDestinationURL, withIntermediateDirectories: true)

        progressHandler(0.05, "开始解压 \(archiveURL.lastPathComponent)...")

        do {
            switch format {
            case .zip:
                try await extractZip(archiveURL: archiveURL, destinationURL: finalDestinationURL, options: options, progressHandler: progressHandler)

            case .tar, .tarGz, .tarBz2, .tarXz:
                try await extractTar(archiveURL: archiveURL, destinationURL: finalDestinationURL, progressHandler: progressHandler)

            case .dmg, .iso:
                try await extractDiskImage(imageURL: archiveURL, destinationURL: finalDestinationURL, progressHandler: progressHandler)

            case .sevenZip:
                try await extractSevenZip(archiveURL: archiveURL, destinationURL: finalDestinationURL, options: options, progressHandler: progressHandler)

            case .rar:
                try await extractRar(archiveURL: archiveURL, destinationURL: finalDestinationURL, options: options, progressHandler: progressHandler)
            }

            progressHandler(1.0, "解压完成！文件保存在: \(finalDestinationURL.lastPathComponent)")
            return finalDestinationURL
        } catch {
            // 3. 中途取消或失败保护：清理只解压了一半的残缺文件，避免留下损坏文件夹
            if fileManager.fileExists(atPath: finalDestinationURL.path) {
                try? fileManager.removeItem(at: finalDestinationURL)
            }
            throw error
        }
    }

    /// 取消解压
    public func cancel() {
        processRunner.cancel()
    }

    private func makeUniqueDirectoryURL(targetURL: URL) -> URL {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: targetURL.path) {
            return targetURL
        }

        let parentDir = targetURL.deletingLastPathComponent()
        let baseName = targetURL.lastPathComponent

        var counter = 1
        while true {
            let candidateName = "\(baseName) (\(counter))"
            let candidateURL = parentDir.appendingPathComponent(candidateName)
            if !fileManager.fileExists(atPath: candidateURL.path) {
                return candidateURL
            }
            counter += 1
        }
    }

    // MARK: - ZIP 解压 (系统 /usr/bin/unzip)

    private func extractZip(
        archiveURL: URL,
        destinationURL: URL,
        options: ExtractionOptions,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        guard let unzipBin = toolDetector.executableURL(for: .unzip) else {
            try await extractTar(archiveURL: archiveURL, destinationURL: destinationURL, progressHandler: progressHandler)
            return
        }

        var args = ["-q"]
        if options.overwriteExisting || options.collisionStrategy == .overwrite {
            args.append("-o")
        }
        if let password = options.password, !password.isEmpty {
            args.append("-P")
            args.append(password)
        }

        args.append(archiveURL.path)
        args.append("-d")
        args.append(destinationURL.path)

        try await processRunner.run(
            executableURL: unzipBin,
            arguments: args
        ) { _ in
            progressHandler(0.5, "正在解压 ZIP 项目...")
        }
    }

    // MARK: - TAR / GZ / BZ2 / XZ 解压 (系统 /usr/bin/tar)

    private func extractTar(
        archiveURL: URL,
        destinationURL: URL,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        guard let tarBin = toolDetector.executableURL(for: .tar) else {
            throw CompressionError.missingExecutable("tar (/usr/bin/tar)")
        }

        let args = ["-xf", archiveURL.path, "-C", destinationURL.path]

        try await processRunner.run(
            executableURL: tarBin,
            arguments: args
        ) { line in
            progressHandler(0.5, "正在提取: \(line)")
        }
    }

    // MARK: - DMG / ISO 磁盘镜像挂载并提取文件

    private func extractDiskImage(
        imageURL: URL,
        destinationURL: URL,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        guard let hdiutilBin = toolDetector.executableURL(for: .hdiutil) else {
            throw CompressionError.missingExecutable("hdiutil (/usr/bin/hdiutil)")
        }

        let mountPoint = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("macCompress_mount_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: mountPoint, withIntermediateDirectories: true)

        defer {
            let detachProcess = Process()
            detachProcess.executableURL = hdiutilBin
            detachProcess.arguments = ["detach", mountPoint.path, "-force"]
            try? detachProcess.run()
            detachProcess.waitUntilExit()
            try? FileManager.default.removeItem(at: mountPoint)
        }

        progressHandler(0.2, "正在只读挂载磁盘镜像...")

        let attachArgs = [
            "attach",
            "-nobrowse",
            "-readonly",
            "-mountpoint", mountPoint.path,
            imageURL.path
        ]

        try await processRunner.run(
            executableURL: hdiutilBin,
            arguments: attachArgs
        )

        progressHandler(0.5, "正在从镜像中提取文件...")

        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: mountPoint, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

        for (index, itemURL) in contents.enumerated() {
            let destItemURL = destinationURL.appendingPathComponent(itemURL.lastPathComponent)
            if fileManager.fileExists(atPath: destItemURL.path) {
                try? fileManager.removeItem(at: destItemURL)
            }
            try fileManager.copyItem(at: itemURL, to: destItemURL)

            let progress = 0.5 + (Double(index + 1) / Double(contents.count)) * 0.45
            progressHandler(progress, "正在提取: \(itemURL.lastPathComponent)")
        }
    }

    // MARK: - 7-Zip 解压

    private func extractSevenZip(
        archiveURL: URL,
        destinationURL: URL,
        options: ExtractionOptions,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        if let sevenZipBin = toolDetector.executableURL(for: .sevenZip) {
            var args = ["x", archiveURL.path, "-o\(destinationURL.path)", "-y"]
            if let password = options.password, !password.isEmpty {
                args.append("-p\(password)")
            }
            try await processRunner.run(executableURL: sevenZipBin, arguments: args) { line in
                progressHandler(0.5, line)
            }
            return
        }

        if let unarBin = toolDetector.executableURL(for: .unar) {
            var args = ["-o", destinationURL.path, archiveURL.path]
            if let password = options.password, !password.isEmpty {
                args.append("-p")
                args.append(password)
            }
            try await processRunner.run(executableURL: unarBin, arguments: args)
            return
        }

        do {
            try await extractTar(archiveURL: archiveURL, destinationURL: destinationURL, progressHandler: progressHandler)
        } catch {
            throw CompressionError.missingExecutable("7-Zip 工具缺失。请通过终端执行 'brew install sevenzip' 进行安装。")
        }
    }

    // MARK: - RAR 解压

    private func extractRar(
        archiveURL: URL,
        destinationURL: URL,
        options: ExtractionOptions,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws {
        if let unarBin = toolDetector.executableURL(for: .unar) {
            var args = ["-o", destinationURL.path, archiveURL.path]
            if let password = options.password, !password.isEmpty {
                args.append("-p")
                args.append(password)
            }
            try await processRunner.run(executableURL: unarBin, arguments: args) { line in
                progressHandler(0.5, line)
            }
            return
        }

        if let sevenZipBin = toolDetector.executableURL(for: .sevenZip) {
            var args = ["x", archiveURL.path, "-o\(destinationURL.path)", "-y"]
            if let password = options.password, !password.isEmpty {
                args.append("-p\(password)")
            }
            try await processRunner.run(executableURL: sevenZipBin, arguments: args)
            return
        }

        if let unarBin = toolDetector.executableURL(for: .unrar) {
            var args = ["x", "-y", archiveURL.path, destinationURL.path]
            if let password = options.password, !password.isEmpty {
                args.append("-p\(password)")
            }
            try await processRunner.run(executableURL: unarBin, arguments: args)
            return
        }

        throw CompressionError.missingExecutable("""
        系统未检测到 RAR 解压器。
        建议解决方案：
        终端执行：brew install unar
        或执行：brew install sevenzip
        安装完成后即可自动支持所有 RAR 解压。
        """)
    }
}
