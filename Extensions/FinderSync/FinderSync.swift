//
//  FinderSync.swift
//  macCompressFinderSync
//
//  职责：Finder Sync 扩展插件核心，注入访达右键上下文菜单（Contextual Menu），
//       获取用户在访达中选中的文件/文件夹路径，并唤醒主 App 进行归档压缩。
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        NSLog("macCompress FinderSync 插件已加载启动")
        // 监听用户的整个个人目录或通用工作区
        let homeDirectory = URL(fileURLWithPath: NSHomeDirectory())
        FIFinderSyncController.default().directoryURLs = [homeDirectory]
    }

    // MARK: - 访达上下文菜单注入 (Contextual Menu)

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "macCompress")

        // 仅在右键选中具体文件或文件夹时展示上下文菜单
        if menuKind == .contextualMenuForItems {
            let compressItem = NSMenuItem(
                title: "用 macCompress 压缩...",
                action: #selector(compressSelectedItems(_:)),
                keyEquivalent: ""
            )
            if let icon = NSImage(systemSymbolName: "archivebox", accessibilityDescription: nil) {
                compressItem.image = icon
            }
            menu.addItem(compressItem)

            let extractItem = NSMenuItem(
                title: "用 macCompress 解压到此处...",
                action: #selector(extractSelectedItems(_:)),
                keyEquivalent: ""
            )
            if let icon = NSImage(systemSymbolName: "arrow.down.doc", accessibilityDescription: nil) {
                extractItem.image = icon
            }
            menu.addItem(extractItem)
        }

        return menu
    }

    // MARK: - 菜单事件响应

    @IBAction func compressSelectedItems(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(), !items.isEmpty else {
            return
        }

        // 通过自定义 URL Scheme (maccompress://compress?paths=...) 唤醒主 App
        launchMainApp(with: "compress", items: items)
    }

    @IBAction func extractSelectedItems(_ sender: AnyObject?) {
        guard let items = FIFinderSyncController.default().selectedItemURLs(), !items.isEmpty else {
            return
        }

        launchMainApp(with: "extract", items: items)
    }

    private func launchMainApp(with action: String, items: [URL]) {
        let paths = items.map { $0.path }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: paths),
              let base64String = jsonData.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "maccompress://\(action)?payload=\(base64String)") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
