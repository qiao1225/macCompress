//
//  MainViewModel.swift
//  macCompress
//
//  职责：MVVM 核心视图模型，统筹拖拽接收、文件项增删、格式配置联动、异步压缩/解压调度与生命周期状态。
//

import Foundation
import SwiftUI
import AppKit

public enum AppTab: String, CaseIterable, Identifiable {
    case compress = "压缩打包"
    case extract = "提取解压"

    public var id: String { rawValue }
}

@MainActor
public final class MainViewModel: ObservableObject {
    // MARK: - 状态属性

    @Published public var activeTab: AppTab = .compress
    @Published public var items: [ArchiveItem] = []
    @Published public var selectedItemIDs: Set<UUID> = []
    
    @Published public var compressionOptions = CompressionOptions()
    @Published public var extractionOptions = ExtractionOptions()
    
    @Published public var status: TaskStatus = .idle
    @Published public var isDropTargeted: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var lastOutputURL: URL? = nil

    // 单压缩包解压模式下的目标文件
    @Published public var archiveToExtract: URL? = nil

    private let compressionEngine = CompressionEngine()
    private let extractionEngine = ExtractionEngine()

    public init() {}

    // MARK: - 文件管理方法

    /// 批量添加文件/文件夹（严格遵循当前激活的 Tab 意图）
    public func addFiles(urls: [URL]) {
        guard !urls.isEmpty else { return }

        // 场景 1：用户当前处于【提取解压】模式，优先载入为解压归档包
        if activeTab == .extract {
            if let firstArchive = urls.first(where: { ArchiveFormat.detect(from: $0) != nil }) {
                self.archiveToExtract = firstArchive
                self.extractionOptions.customFolderName = firstArchive.deletingPathExtension().lastPathComponent
                self.status = .idle
                self.lastOutputURL = nil
                return
            } else if let first = urls.first {
                self.archiveToExtract = first
                self.extractionOptions.customFolderName = first.deletingPathExtension().lastPathComponent
                self.status = .idle
                self.lastOutputURL = nil
                return
            }
        }

        // 场景 2：用户在【压缩打包】模式下，如果当前列表为空且拖入的是单个压缩包，智能切入解压
        if activeTab == .compress && items.isEmpty && urls.count == 1,
           let firstURL = urls.first, ArchiveFormat.detect(from: firstURL) != nil {
            self.archiveToExtract = firstURL
            self.extractionOptions.customFolderName = firstURL.deletingPathExtension().lastPathComponent
            self.activeTab = .extract
            self.status = .idle
            self.lastOutputURL = nil
            return
        }

        // 场景 3：常规添加待压缩文件/文件夹
        let existingPaths = Set(items.map { $0.url.path })
        var newItems: [ArchiveItem] = []

        for url in urls {
            if !existingPaths.contains(url.path) {
                newItems.append(ArchiveItem(url: url))
            }
        }

        items.append(contentsOf: newItems)
        self.status = .idle
        self.lastOutputURL = nil

        // 默认将压缩包命名设置为首个文件的名称
        if compressionOptions.customArchiveName.isEmpty, let first = items.first {
            compressionOptions.customArchiveName = first.url.deletingPathExtension().lastPathComponent
        }
    }

    /// 清空解压信息，恢复初始就绪状态
    public func clearExtraction() {
        self.archiveToExtract = nil
        self.status = .idle
        self.lastOutputURL = nil
    }

    /// 清空压缩信息，恢复初始就绪状态
    public func clearCompression() {
        self.clearAllItems()
    }

    /// 一键清空当前活动标签的所有信息与状态
    public func resetCurrentTab() {
        if activeTab == .compress {
            clearCompression()
        } else {
            clearExtraction()
        }
    }

    /// 解析外部 URL Scheme 调起（来自访达右键扩展或快捷指令）
    public func handleIncomingURL(_ url: URL) {
        guard url.scheme == "maccompress" else { return }
        let action = url.host ?? ""

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItem = components.queryItems?.first(where: { $0.name == "payload" }),
              let base64 = queryItem.value,
              let data = Data(base64Encoded: base64),
              let paths = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return
        }

        let urls = paths.map { URL(fileURLWithPath: $0) }
        if action == "extract", let first = urls.first {
            self.archiveToExtract = first
            self.activeTab = .extract
        } else {
            self.activeTab = .compress
            self.addFiles(urls: urls)
        }
    }

    /// 移除选中项
    public func removeSelectedItems() {
        items.removeAll { selectedItemIDs.contains($0.id) }
        selectedItemIDs.removeAll()
    }

    /// 移除指定项
    public func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        selectedItemIDs.remove(id)
    }

    /// 清空所有项
    public func clearAllItems() {
        items.removeAll()
        selectedItemIDs.removeAll()
        compressionOptions.customArchiveName = ""
        status = .idle
        lastOutputURL = nil
    }

    // MARK: - 压缩任务执行

    public func startCompress() {
        guard !items.isEmpty else {
            self.errorMessage = "请先添加要压缩的文件或文件夹"
            return
        }

        guard !status.isBusy else { return }

        self.status = .preparing(description: "正在检查并初始化任务...")
        self.errorMessage = nil

        let targetItems = items
        let targetOptions = compressionOptions

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let outputURL = try await compressionEngine.compress(
                    items: targetItems,
                    options: targetOptions
                ) { [weak self] progress, currentItem in
                    Task { @MainActor in
                        self?.status = .running(
                            progress: progress,
                            currentItem: currentItem,
                            processedCount: 0,
                            totalCount: targetItems.count
                        )
                    }
                }

                self.lastOutputURL = outputURL
                self.status = .completed(outputURL: outputURL, message: outputURL.lastPathComponent)

                SystemNotificationService.shared.sendCompletionNotification(
                    title: "压缩成功",
                    body: "已成功生成归档文件: \(outputURL.lastPathComponent)",
                    targetURL: outputURL
                )
            } catch {
                if case CompressionError.processCancelled = error {
                    self.status = .cancelled
                } else {
                    self.status = .failed(message: error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - 解压任务执行

    public func startExtract() {
        guard let archiveURL = archiveToExtract else {
            self.errorMessage = "请先选择需要解压的压缩包文件"
            return
        }

        guard !status.isBusy else { return }

        self.status = .preparing(description: "正在准备解压...")
        self.errorMessage = nil
        let targetOptions = extractionOptions

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let destFolderURL = try await extractionEngine.extract(
                    archiveURL: archiveURL,
                    options: targetOptions
                ) { [weak self] progress, desc in
                    Task { @MainActor in
                        self?.status = .running(
                            progress: progress,
                            currentItem: desc,
                            processedCount: 0,
                            totalCount: 1
                        )
                    }
                }

                self.lastOutputURL = destFolderURL
                self.status = .completed(outputURL: destFolderURL, message: destFolderURL.lastPathComponent)

                if targetOptions.revealInFinderWhenFinished {
                    NSWorkspace.shared.activateFileViewerSelecting([destFolderURL])
                }

                SystemNotificationService.shared.sendCompletionNotification(
                    title: "解压完成",
                    body: "文件已解压至: \(destFolderURL.lastPathComponent)",
                    targetURL: destFolderURL
                )
            } catch {
                if case CompressionError.processCancelled = error {
                    self.status = .cancelled
                } else {
                    self.status = .failed(message: error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    /// 取消当前正在进行的任何任务
    public func cancelTask() {
        compressionEngine.cancel()
        extractionEngine.cancel()
        self.status = .cancelled
    }

    /// 在访达中定位输出文件
    public func revealLastOutputInFinder() {
        if let url = lastOutputURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    // MARK: - 原生选择面板调用

    /// 弹出原生文件选择器
    public func presentFilePicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        openPanel.prompt = "添加"

        if openPanel.runModal() == .OK {
            addFiles(urls: openPanel.urls)
        }
    }

    /// 弹出原生输出目录选择器
    public func presentOutputDirectoryPicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.prompt = "选择输出位置"

        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            compressionOptions.customOutputDirectory = selectedURL
            extractionOptions.destinationDirectory = selectedURL
        }
    }
}
