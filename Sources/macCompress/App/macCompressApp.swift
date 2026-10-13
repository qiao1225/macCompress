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
                .onAppear {
                    appDelegate.viewModel = viewModel
                }
                .onOpenURL { url in
                    viewModel.handleIncomingURL(url)
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("添加文件...") {
                    viewModel.presentFilePicker()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }

        // 菜单栏常驻组件 (macOS 13 Ventura+)
        MenuBarExtra("macCompress", systemImage: "archivebox") {
            MenuBarPopoverView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
