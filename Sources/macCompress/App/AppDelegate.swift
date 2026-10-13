//
//  AppDelegate.swift
//  macCompress
//
//  职责：AppKit 应用代理，响应 macOS 系统级事件：Dock 图标拖入、Dock 图标重新点击激活窗口 (Reopen)、窗口生命周期管理。
//

import AppKit
import Foundation
import SwiftUI

public final class MainWindowDelegate: NSObject, NSWindowDelegate {
    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 点击窗口左上角红叉时仅隐藏窗口，不销毁窗口实例与上下文状态
        sender.orderOut(nil)
        return false
    }
}

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static var shared: AppDelegate?
    public weak var viewModel: MainViewModel?
    public weak var mainWindow: NSWindow?
    private let windowDelegate = MainWindowDelegate()

    public override init() {
        super.init()
        AppDelegate.shared = self
    }

    /// 绑定并接管主窗口生命周期代理与现代沉浸式视觉配置
    public func configureMainWindow(_ window: NSWindow) {
        self.mainWindow = window
        window.delegate = windowDelegate

        // 彻底消除突兀灰色系统标题栏，实现与 Marvis 主题完全吻合的沉浸式无缝体验
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true

        // 统一窗口底色与主题 Token 一致
        window.backgroundColor = NSColor(Color.appBackground)
    }

    /// 响应用户把文件拖拽到 Dock 图标上，或者在访达中双击关联文件
    public func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let vm = self.viewModel else { return }
            vm.addFiles(urls: urls)
            if let window = self.mainWindow {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// 应用启动时配置
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    /// 点击 Dock 图标时重新激活主窗口（修复点击红叉 x 后点 Dock 无法弹回的经典系统级 Bug）
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return false
        }

        // 备用兜底：查找可用窗口激活
        for window in sender.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return true
        }
        return true
    }
}
