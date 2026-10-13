//
//  WindowAccessor.swift
//  macCompress
//
//  职责：AppKit 桥接组件，用于捕获当前 SwiftUI 视图所在的宿主 NSWindow 句柄并交由 AppDelegate 托管。
//

import SwiftUI
import AppKit

public struct WindowAccessor: NSViewRepresentable {
    public let onWindow: (NSWindow) -> Void

    public init(onWindow: @escaping (NSWindow) -> Void) {
        self.onWindow = onWindow
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                onWindow(window)
            }
        }
        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}
