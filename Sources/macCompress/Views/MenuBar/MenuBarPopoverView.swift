//
//  MenuBarPopoverView.swift
//  macCompress
//
//  职责：常驻 macOS 菜单栏（Status Item）的迷你快捷面板，支持快速拖放文件和一键唤醒主界面。
//

import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @ObservedObject var viewModel: MainViewModel

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.accentColor)
                Text("macCompress 快捷归档")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }

            Divider()

            VStack(spacing: 8) {
                Text(viewModel.items.isEmpty ? "主窗口未添加文件" : "已就绪 \(viewModel.items.count) 个待压缩项目")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    Button("打开主窗口") {
                        NSApp.activate(ignoringOtherApps: true)
                        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                    .controlSize(.small)

                    Button("退出") {
                        NSApp.terminate(nil)
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(14)
        .frame(width: 240)
    }
}
