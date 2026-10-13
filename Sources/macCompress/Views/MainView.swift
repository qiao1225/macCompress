//
//  MainView.swift
//  macCompress
//
//  职责：macOS 现代化左侧窄边栏布局，清空突兀顶栏，支持 macOS Vibrancy 毛玻璃侧边栏、主工作区自适应与全屏拖拽感知。
//

import SwiftUI
import UniformTypeIdentifiers

public struct MainView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.colorScheme) var colorScheme

    public init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack(spacing: 0) {
            // 1. 左侧常驻固定边栏 (macOS Vibrancy 毛玻璃底衬)
            SidebarView(viewModel: viewModel)

            // 2. 右侧主工作区 (顶部通透无冗余横梁)
            VStack(spacing: 0) {
                // 核心工作区 (随侧边栏宽度平滑弹性自适应)
                ZStack {
                    if viewModel.activeTab == .compress {
                        compressWorkspaceView
                            .transition(.opacity.combined(with: .scale(scale: 0.995)))
                    } else {
                        extractWorkspaceView
                            .transition(.opacity.combined(with: .scale(scale: 0.995)))
                    }
                }
                .animation(ThemeTokens.Motion.pageTransition, value: viewModel.activeTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 16)

                // 底部状态与流光进度条 (无重复功能按钮)
                ExecutionStatusBarView(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground)
        }
        .frame(minWidth: 720, minHeight: 520)
        // 捕获宿主 NSWindow 并委托给 AppDelegate
        .background(
            WindowAccessor { window in
                AppDelegate.shared?.configureMainWindow(window)
            }
        )
        // 全局拖拽文件接收器
        .onDrop(of: [.fileURL], isTargeted: $viewModel.isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .alert("提示", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - 压缩工作区

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
                .frame(minWidth: 320, maxWidth: 380)
            }
        }
    }

    // MARK: - 解压工作区

    @ViewBuilder
    private var extractWorkspaceView: some View {
        ExtractionConfigView(viewModel: viewModel)
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
