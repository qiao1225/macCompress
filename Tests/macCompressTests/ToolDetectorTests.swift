//
//  ToolDetectorTests.swift
//  macCompressTests
//
//  职责：测试系统自带工具（zip、tar、unzip、hdiutil）的探测可用性。
//

import XCTest
@testable import macCompress

final class ToolDetectorTests: XCTestCase {
    func testSystemToolsDetection() {
        let detector = ToolDetector.shared

        // macOS 必须具备原生 /usr/bin/zip 与 /usr/bin/tar
        XCTAssertNotNil(detector.executableURL(for: .zip), "系统必须探测到 zip 工具")
        XCTAssertNotNil(detector.executableURL(for: .tar), "系统必须探测到 tar/bsdtar 工具")
        XCTAssertNotNil(detector.executableURL(for: .hdiutil), "系统必须探测到 hdiutil 工具")
    }

    func testArchiveFormatDetection() {
        let zipURL = URL(fileURLWithPath: "/tmp/sample.zip")
        XCTAssertEqual(ArchiveFormat.detect(from: zipURL), .zip)

        let tarGzURL = URL(fileURLWithPath: "/tmp/archive.tar.gz")
        XCTAssertEqual(ArchiveFormat.detect(from: tarGzURL), .tarGz)

        let tgzURL = URL(fileURLWithPath: "/tmp/archive.tgz")
        XCTAssertEqual(ArchiveFormat.detect(from: tgzURL), .tarGz)

        let dmgURL = URL(fileURLWithPath: "/tmp/installer.dmg")
        XCTAssertEqual(ArchiveFormat.detect(from: dmgURL), .dmg)
    }
}
