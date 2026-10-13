//
//  FileDropZoneView.swift
//  macCompress
//
//  职责：空状态拖拽接收区，遵循 Apple HIG 设计规范，提供清晰的拖拽虚线区域、悬停高亮反馈及快速选取按钮。
//

import SwiftUI
import UniformTypeIdentifiers

public struct FileDropZoneView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var isHovering = false

    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(viewModel.isDropTargeted ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                    .frame(width: 84, height: 84)

                Image(systemName: viewModel.isDropTargeted ? "arrow.down.doc.fill" : "plus.viewfinder")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(viewModel.isDropTargeted ? .accentColor : .secondary)
                    .scaleEffect(viewModel.isDropTargeted ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isDropTargeted)
            }

            VStack(spacing: 6) {
                Text(viewModel.isDropTargeted ? "松开鼠标立即添加" : "拖拽文件或文件夹至此")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("支持同时批量拖入多个文件或文件夹，或点击下方按钮选择")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                viewModel.presentFilePicker()
            }) {
                Label("选取文件...", systemImage: "folder.badge.plus")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(viewModel.isDropTargeted ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    viewModel.isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.25),
                    style: StrokeStyle(lineWidth: viewModel.isDropTargeted ? 2.5 : 1.5, dash: [8, 6])
                )
        )
        .padding(24)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isDropTargeted)
    }
}
