//
//  macCompressApp.swift
//  macCompress
//
//  职责：SwiftUI 应用主入口，挂载 AppDelegate 监听系统事件，构建主窗口与可选菜单栏常驻组件。
//

import SwiftUI
import AppKit

@main
struct macCompressApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = MainViewModel()

    init() {
        // 请求通知中心授权
        SystemNotificationService.shared.requestAuthorization()
    }

    var body: some Scene {
        // 主操作窗口
        WindowGroup {
            MainView(viewModel: viewModel)
                .ignoresSafeArea(.all, edges: .top)
                .onAppear {
                    appDelegate.viewModel = viewModel
                }
                .onOpenURL { url in
                    viewModel.handleIncomingURL(url)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("添加文件...") {
                    viewModel.presentFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }

        // 菜单栏常驻组件 (macOS 最上方状态栏小图标，基于机器人拉链箱定制)
        MenuBarExtra {
            MenuBarPopoverView(viewModel: viewModel)
        } label: {
            Image(nsImage: menuBarIcon)
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarIcon: NSImage {
        if let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            img.isTemplate = true
            img.size = NSSize(width: 18, height: 18)
            return img
        }
        for path in ["Resources/MenuBarIcon.png", "MenuBarIcon.png"] {
            if let img = NSImage(contentsOfFile: path) {
                img.isTemplate = true
                img.size = NSSize(width: 18, height: 18)
                return img
            }
        }
        let fallback = NSImage(systemSymbolName: "archivebox", accessibilityDescription: "macCompress") ?? NSImage()
        fallback.isTemplate = true
        return fallback
    }
}
