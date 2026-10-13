//
//  AppKitIconView.swift
//  macCompress
//
//  职责：将 AppKit 的 NSImage 系统图标无缝桥接至 SwiftUI 视图，提供保真度与抗锯齿渲染。
//

import SwiftUI
import AppKit

public struct AppKitIconView: View {
    public let image: NSImage
    public var size: CGFloat = 28

    public init(image: NSImage, size: CGFloat = 28) {
        self.image = image
        self.size = size
    }

    public var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}
