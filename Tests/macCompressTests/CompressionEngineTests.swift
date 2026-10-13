//
//  CompressionEngineTests.swift
//  macCompressTests
//
//  职责：验证真实文件压缩与解压流程，测试包含中文、空格、特殊字符路径时的子进程鲁棒性。
//

import XCTest
@testable import macCompress

final class CompressionEngineTests: XCTestCase {
    var tempDirectory: URL!

    override func setUpWithError() throws {
        // 创建带有中文与空格的测试临时目录
        let baseTemp = URL(fileURLWithPath: NSTemporaryDirectory())
        let folderName = "macCompress 测试 空间 (test)_\(UUID().uuidString)"
        tempDirectory = baseTemp.appendingPathComponent(folderName)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temp = tempDirectory {
            try? FileManager.default.removeItem(at: temp)
        }
    }

    func testZipCompressionWithChineseAndSpaces() async throws {
        // 1. 创建包含中文与空格的样本文件
        let testFileURL = tempDirectory.appendingPathComponent("测试文档 示例 (sample).txt")
        let sampleContent = "你好，macOS 原生压缩！这是用于验证路径处理的测试数据。"
        try sampleContent.write(to: testFileURL, atomically: true, encoding: .utf8)

        let item = ArchiveItem(url: testFileURL)
        let engine = CompressionEngine()

        var options = CompressionOptions()
        options.format = .zip
        options.compressionLevel = 6
        options.customArchiveName = "测试输出 压缩包"

        // 2. 执行压缩
        let outputZipURL = try await engine.compress(items: [item], options: options) { progress, desc in
            // 进度检查
            XCTAssertGreaterThanOrEqual(progress, 0.0)
        }

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputZipURL.path), "生成的 zip 文件必须存在于磁盘中")

        // 3. 执行解压验证
        let extractionEngine = ExtractionEngine()
        let extractDest = tempDirectory.appendingPathComponent("解压目标 目录")
        var extractionOptions = ExtractionOptions()
        extractionOptions.destinationDirectory = extractDest
        extractionOptions.createSubfolder = false

        _ = try await extractionEngine.extract(archiveURL: outputZipURL, options: extractionOptions) { _, _ in }

        let extractedFileURL = extractDest.appendingPathComponent(testFileURL.lastPathComponent)
        XCTAssertTrue(FileManager.default.fileExists(atPath: extractedFileURL.path), "解压后原中文文件必须正确还原")

        let restoredContent = try String(contentsOf: extractedFileURL, encoding: .utf8)
        XCTAssertEqual(restoredContent, sampleContent, "解压后的文本内容必须与原文件完全一致")
    }

    func testTarGzCompression() async throws {
        let testFileURL = tempDirectory.appendingPathComponent("data_archive.log")
        try "Log test content for tar.gz".write(to: testFileURL, atomically: true, encoding: .utf8)

        let item = ArchiveItem(url: testFileURL)
        let engine = CompressionEngine()

        var options = CompressionOptions()
        options.format = .tarGz
        options.compressionLevel = 9
        options.customArchiveName = "output_tar"

        let outputURL = try await engine.compress(items: [item], options: options) { _, _ in }
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertTrue(outputURL.lastPathComponent.hasSuffix(".tar.gz"))
    }
}
