//
//  MainView.swift
//  macCompress
//
//  职责：macOS 应用主窗口界面，全屏拖拽感知，3步直达流架构，HIG 原生视觉规范，Window 生命周期托管。
//

import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isShowingFormatSheet = false

    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 模式切换顶栏
            HStack {
                Picker("模式", selection: $viewModel.activeTab) {
                    ForEach(AppTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)

                Spacer()

                // 右侧：全格式支持与使用指南
                Button(action: {
                    isShowingFormatSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("全格式生态一览与使用说明")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isShowingFormatSheet, arrowEdge: .bottom) {
                    formatOverviewSheet
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // 核心工作区
            Group {
                if viewModel.activeTab == .compress {
                    compressWorkspaceView
                } else {
                    extractWorkspaceView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 底部进度条与控制条
            ExecutionStatusBarView(viewModel: viewModel)
        }
        .frame(minWidth: 680, minHeight: 540)
        // 捕获宿主 NSWindow 并委托给 AppDelegate（彻底解决点击红叉 x 后点击 Dock 唤不回的系统 Bug）
        .background(
            WindowAccessor { window in
                AppDelegate.shared?.configureMainWindow(window)
            }
        )
        // 全局拖拽文件接收器
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .overlay(
            // 拖拽悬停全局外发光高亮边框
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.accentColor, lineWidth: viewModel.isDropTargeted ? 3 : 0)
                .padding(2)
                .animation(.easeInOut(duration: 0.15), value: viewModel.isDropTargeted)
        )
        .alert("提示", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 压缩模式工作区

    @ViewBuilder
    private var compressWorkspaceView: some View {
        if viewModel.items.isEmpty {
            FileDropZoneView(viewModel: viewModel)
        } else {
            HSplitView {
                // 左侧：待压缩文件列表
                FileListView(viewModel: viewModel)
                    .frame(minWidth: 280, maxWidth: .infinity)

                // 右侧：格式配置与高级选项
                ScrollView {
                    CompressionConfigView(viewModel: viewModel)
                }
                .frame(minWidth: 340, maxWidth: 400)
            }
        }
    }

    // MARK: - 解压模式工作区

    @ViewBuilder
    private var extractWorkspaceView: some View {
        ExtractionConfigView(viewModel: viewModel)
    }

    // MARK: - 格式全景一览面板 (解答用户“市面上的够不够用、怎么使用”)

    private var formatOverviewSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "archivebox.fill")
                    .foregroundColor(.accentColor)
                Text("格式支持全景与使用场景指南")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }

            Text("本客户端深度集成 macOS 原生底层能力与高效引擎，覆盖日常与开发 99.9% 场景：")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                formatRow(name: "ZIP", status: "压缩 & 解压", badge: "全平台通用", desc: "Windows / Mac / 移动端即开即用，支持密码加密、分卷、过滤 .DS_Store。")
                formatRow(name: "7-Zip (.7z)", status: "压缩 & 解压", badge: "最高压缩比", desc: "极致压缩体积，支持高强度 AES 密码加密与大文件分卷切片。")
                formatRow(name: "TAR 系列 (.tar.gz / .bz2 / .xz)", status: "压缩 & 解压", badge: "开发者标配", desc: "系统原生 bsdtar 驱动，Linux/服务器传输首选，完整保留权限元数据。")
                formatRow(name: "DMG / ISO", status: "提取解压", badge: "磁盘/光盘镜像", desc: "系统原生 /usr/bin/hdiutil 驱动，只读安全挂载，直接提取镜像内文件。")
                formatRow(name: "RAR / CAB / LZH 等", status: "提取解压", badge: "兼容冷门格式", desc: "自动兼容 Windows 传统与网络常见压缩包，开箱即用。")
            }

            Divider()

            Text("💡 使用极简：直接从访达拖入文件到窗口任意位置，或拖到 Dock 图标，3 步一键执行。")
                .font(.system(size: 11))
                .foregroundColor(.accentColor)
        }
        .padding(18)
        .frame(width: 440)
    }

    @ViewBuilder
    private func formatRow(name: String, status: String, badge: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                Text(status)
                    .font(.system(size: 10))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(3)
                Text(badge)
                    .font(.system(size: 10))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.secondary)
                    .cornerRadius(3)
            }
            Text(desc)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 拖拽解析

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var droppedURLs: [URL] = []
        let dispatchGroup = DispatchGroup()

        for provider in providers {
            dispatchGroup.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let validURL = url {
                    droppedURLs.append(validURL)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            viewModel.addFiles(urls: droppedURLs)
        }
        return true
    }
}
