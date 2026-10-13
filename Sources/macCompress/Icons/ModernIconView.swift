//
//  ModernIconView.swift
//  macCompress
//
//  职责：现代 SaaS 风格矢量图标渲染引擎，支持 1.5-2px 圆角线条、微渐变面填充、高光微晕与 16/20/24/32px 四档对齐。
//

import SwiftUI

public struct ModernIconView: View {
    public let type: ModernIconType
    public var size: CGFloat
    public var style: ModernIconStyle

    public init(
        _ type: ModernIconType,
        size: ModernIconSize = .lg,
        style: ModernIconStyle = .primaryGradient
    ) {
        self.type = type
        self.size = size.pointSize
        self.style = style
    }

    public init(
        _ type: ModernIconType,
        customSize: CGFloat,
        style: ModernIconStyle = .primaryGradient
    ) {
        self.type = type
        self.size = customSize
        self.style = style
    }

    private var strokeWidth: CGFloat {
        size <= 16 ? 1.8 : 2.0
    }

    public var body: some View {
        ZStack {
            iconContent
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var iconContent: some View {
        switch type {
        case .archiveBox:
            archiveBoxIcon
        case .extract:
            extractIcon
        case .lockSecurity:
            lockSecurityIcon
        case .splitVolume:
            splitVolumeIcon
        case .folder:
            folderIcon
        case .settings:
            settingsIcon
        case .compressing:
            compressingIcon
        case .statusSuccess:
            statusSuccessIcon
        case .statusWarning:
            statusWarningIcon
        case .statusError:
            statusErrorIcon
        case .fileGeneric:
            fileGenericIcon
        case .previewEye:
            previewEyeIcon
        case .trashClean:
            trashCleanIcon
        case .finderReveal:
            finderRevealIcon
        case .badgeSeal:
            badgeSealIcon
        }
    }

    // MARK: - 颜色与材质解析 (统一收敛至紫色阶)

    private var primaryTint: Color {
        switch style {
        case .monochrome(let color): return color
        case .primaryGradient, .accentGlow: return ColorTokens.Purple.p500
        case .dualTone(let primary, _): return primary
        case .semanticSuccess: return ColorTokens.Semantic.successLight
        case .semanticWarning: return ColorTokens.Semantic.warningLight
        case .semanticError: return ColorTokens.Semantic.errorLight
        }
    }

    private var secondaryTint: Color {
        switch style {
        case .monochrome(let color): return color.opacity(0.35)
        case .primaryGradient: return ColorTokens.Purple.p400
        case .accentGlow: return ColorTokens.Purple.p300
        case .dualTone(_, let secondary): return secondary
        case .semanticSuccess: return ColorTokens.Semantic.successDark
        case .semanticWarning: return ColorTokens.Semantic.warningDark
        case .semanticError: return ColorTokens.Semantic.errorDark
        }
    }

    private var fillGradient: LinearGradient {
        LinearGradient(
            colors: [ColorTokens.Purple.p400.opacity(0.28), ColorTokens.Purple.p600.opacity(0.18)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var strokeGradient: LinearGradient {
        LinearGradient(
            colors: [primaryTint, secondaryTint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - 1. 压缩包 / 赛博拉链归档箱 (ArchiveBox - 基于 3D 机器人拉链箱原型)
    private var archiveBoxIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height
            let r: CGFloat = w * 0.16

            // 箱体轮廓与柔和微填充 (圆角深色箱体)
            let boxRect = CGRect(x: w * 0.14, y: h * 0.28, width: w * 0.72, height: h * 0.60)
            let boxPath = Path(roundedRect: boxRect, cornerRadius: r)
            context.fill(boxPath, with: .color(primaryTint.opacity(0.18)))
            context.stroke(boxPath, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 1. 左上方弧形入袋压缩箭头 (Cyan Downward Curve Arrow)
            var arrowPath = Path()
            arrowPath.addArc(
                center: CGPoint(x: w * 0.32, y: h * 0.22),
                radius: w * 0.18,
                startAngle: .degrees(150),
                endAngle: .degrees(350),
                clockwise: false
            )
            context.stroke(arrowPath, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth * 0.9, lineCap: .round))

            // 箭头尖端
            var arrowHead = Path()
            arrowHead.move(to: CGPoint(x: w * 0.40, y: h * 0.18))
            arrowHead.addLine(to: CGPoint(x: w * 0.50, y: h * 0.24))
            arrowHead.addLine(to: CGPoint(x: w * 0.42, y: h * 0.30))
            context.stroke(arrowHead, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth * 0.9, lineCap: .round, lineJoin: .round))

            // 2. 正面金属拉链导轨与拉环 (Zipper Track & Puller)
            var zipLine = Path()
            zipLine.move(to: CGPoint(x: w * 0.50, y: h * 0.28))
            zipLine.addLine(to: CGPoint(x: w * 0.50, y: h * 0.88))
            context.stroke(zipLine, with: .color(primaryTint.opacity(0.35)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [1.5, 1.5]))

            // 拉链滑块与拉环 (Puller Tag)
            let pullerRect = CGRect(x: w * 0.43, y: h * 0.46, width: w * 0.14, height: h * 0.24)
            let pullerPath = Path(roundedRect: pullerRect, cornerRadius: w * 0.05)
            context.fill(pullerPath, with: .color(secondaryTint))
            context.stroke(pullerPath, with: .color(primaryTint), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))

            // 拉环孔
            let holeRect = CGRect(x: w * 0.465, y: h * 0.58, width: w * 0.07, height: h * 0.08)
            context.fill(Path(roundedRect: holeRect, cornerRadius: 1), with: .color(primaryTint.opacity(0.25)))

            // 3. 左下侧标志性 4 点阵像素块 (Signature 4-Pixel Matrix)
            let dotSize: CGFloat = max(1.2, w * 0.05)
            let dotGap: CGFloat = dotSize * 1.5
            let startX: CGFloat = w * 0.23
            let startY: CGFloat = h * 0.48
            for col in 0..<2 {
                for row in 0..<2 {
                    let dRect = CGRect(x: startX + CGFloat(col) * dotGap, y: startY + CGFloat(row) * dotGap, width: dotSize, height: dotSize)
                    context.fill(Path(roundedRect: dRect, cornerRadius: 0.6), with: .color(primaryTint.opacity(col == 1 && row == 0 ? 0.35 : 0.85)))
                }
            }
        }
    }

    // MARK: - 2. 解压 / 展开 (Extract - 基于 3D 原型右下 Neon Green 弧形抽出箭头)
    private var extractIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height
            let r: CGFloat = w * 0.16

            // 箱体轮廓 (拉链已展开半开箱体)
            let boxRect = CGRect(x: w * 0.14, y: h * 0.36, width: w * 0.72, height: h * 0.52)
            let boxPath = Path(roundedRect: boxRect, cornerRadius: r)
            context.fill(boxPath, with: .color(secondaryTint.opacity(0.18)))
            context.stroke(boxPath, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 左下侧 4 点阵像素块 (与原型一致)
            let dotSize: CGFloat = max(1.2, w * 0.05)
            let dotGap: CGFloat = dotSize * 1.5
            let startX: CGFloat = w * 0.23
            let startY: CGFloat = h * 0.56
            for col in 0..<2 {
                for row in 0..<2 {
                    let dRect = CGRect(x: startX + CGFloat(col) * dotGap, y: startY + CGFloat(row) * dotGap, width: dotSize, height: dotSize)
                    context.fill(Path(roundedRect: dRect, cornerRadius: 0.6), with: .color(secondaryTint.opacity(0.75)))
                }
            }

            // 标志性右侧上扬拔出弧形箭头 (Upward Curved Extract Arrow)
            var arcArrow = Path()
            arcArrow.move(to: CGPoint(x: w * 0.48, y: h * 0.64))
            arcArrow.addQuadCurve(
                to: CGPoint(x: w * 0.76, y: h * 0.18),
                control: CGPoint(x: w * 0.88, y: h * 0.52)
            )
            context.stroke(arcArrow, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth * 1.1, lineCap: .round))

            // 上扬箭头头部
            var arrowHead = Path()
            arrowHead.move(to: CGPoint(x: w * 0.62, y: h * 0.22))
            arrowHead.addLine(to: CGPoint(x: w * 0.76, y: h * 0.16))
            arrowHead.addLine(to: CGPoint(x: w * 0.82, y: h * 0.30))
            context.stroke(arrowHead, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth * 1.1, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - 3. 加密 / 安全锁 (LockSecurity)
    private var lockSecurityIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 锁体 (面)
            let bodyRect = CGRect(x: w * 0.20, y: h * 0.42, width: w * 0.60, height: h * 0.46)
            let bodyPath = Path(roundedRect: bodyRect, cornerRadius: w * 0.14)
            context.fill(bodyPath, with: .color(primaryTint.opacity(0.2)))
            context.stroke(bodyPath, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 圆润锁环 (U-Shape)
            var shackle = Path()
            shackle.move(to: CGPoint(x: w * 0.32, y: h * 0.42))
            shackle.addLine(to: CGPoint(x: w * 0.32, y: h * 0.28))
            shackle.addArc(
                center: CGPoint(x: w * 0.5, y: h * 0.28),
                radius: w * 0.18,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            shackle.addLine(to: CGPoint(x: w * 0.68, y: h * 0.42))
            context.stroke(shackle, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 锁孔点
            let holeRect = CGRect(x: w * 0.46, y: h * 0.58, width: w * 0.08, height: w * 0.08)
            let holePath = Path(ellipseIn: holeRect)
            context.fill(holePath, with: .color(primaryTint))
            
            var keyholeLine = Path()
            keyholeLine.move(to: CGPoint(x: w * 0.5, y: h * 0.64))
            keyholeLine.addLine(to: CGPoint(x: w * 0.5, y: h * 0.74))
            context.stroke(keyholeLine, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth * 0.9, lineCap: .round))
        }
    }

    // MARK: - 4. 分卷 / 切片 (SplitVolume)
    private var splitVolumeIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 3片堆叠层
            for i in 0..<3 {
                let yOffset = CGFloat(i) * (h * 0.22)
                let rect = CGRect(x: w * 0.15, y: h * 0.18 + yOffset, width: w * 0.7, height: h * 0.16)
                let path = Path(roundedRect: rect, cornerRadius: 4)
                let alpha = 0.15 + Double(i) * 0.08
                context.fill(path, with: .color(primaryTint.opacity(alpha)))
                context.stroke(path, with: .color(i == 0 ? primaryTint : secondaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
            }

            // 竖向切分指示虚线
            var cutLine = Path()
            cutLine.move(to: CGPoint(x: w * 0.65, y: h * 0.12))
            cutLine.addLine(to: CGPoint(x: w * 0.65, y: h * 0.88))
            context.stroke(cutLine, with: .color(secondaryTint), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [2, 3]))
        }
    }

    // MARK: - 5. 现代文件夹 (Folder)
    private var folderIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 背板
            var backPath = Path()
            backPath.move(to: CGPoint(x: w * 0.15, y: h * 0.3))
            backPath.addLine(to: CGPoint(x: w * 0.4, y: h * 0.3))
            backPath.addLine(to: CGPoint(x: w * 0.48, y: h * 0.38))
            backPath.addLine(to: CGPoint(x: w * 0.85, y: h * 0.38))
            backPath.addArc(tangent1End: CGPoint(x: w * 0.88, y: h * 0.38), tangent2End: CGPoint(x: w * 0.88, y: h * 0.78), radius: 4)
            backPath.addLine(to: CGPoint(x: w * 0.88, y: h * 0.78))
            backPath.addLine(to: CGPoint(x: w * 0.12, y: h * 0.78))
            backPath.closeSubpath()
            context.fill(backPath, with: .color(primaryTint.opacity(0.18)))

            // 前盖卡片
            let frontRect = CGRect(x: w * 0.12, y: h * 0.42, width: w * 0.76, height: h * 0.42)
            let frontPath = Path(roundedRect: frontRect, cornerRadius: 5)
            context.fill(frontPath, with: .color(secondaryTint.opacity(0.24)))
            context.stroke(frontPath, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - 6. 设置与调节 (Settings)
    private var settingsIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 现代 3 档调节滑块
            let yPositions = [h * 0.3, h * 0.5, h * 0.7]
            let thumbPositions = [w * 0.38, w * 0.68, w * 0.46]

            for i in 0..<3 {
                let y = yPositions[i]
                var track = Path()
                track.move(to: CGPoint(x: w * 0.18, y: y))
                track.addLine(to: CGPoint(x: w * 0.82, y: y))
                context.stroke(track, with: .color(primaryTint.opacity(0.4)), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

                // 滑块点
                let tx = thumbPositions[i]
                let knobRect = CGRect(x: tx - w * 0.08, y: y - w * 0.08, width: w * 0.16, height: w * 0.16)
                let knobPath = Path(ellipseIn: knobRect)
                context.fill(knobPath, with: .color(secondaryTint))
                context.stroke(knobPath, with: .color(primaryTint), style: StrokeStyle(lineWidth: 1.2))
            }
        }
    }

    // MARK: - 7. 压缩向心处理中 / 双向循环流 (Compressing - 双弧形环绕循环)
    private var compressingIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 居中微型拉链箱体
            let centerRect = CGRect(x: w * 0.35, y: h * 0.35, width: w * 0.30, height: h * 0.30)
            let centerPath = Path(roundedRect: centerRect, cornerRadius: 2.5)
            context.fill(centerPath, with: .color(primaryTint.opacity(0.25)))
            context.stroke(centerPath, with: .color(primaryTint), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))

            // 1. 上弧形入袋箭头 (模拟 3D 青蓝入袋弧线)
            var topArc = Path()
            topArc.addArc(
                center: CGPoint(x: w * 0.5, y: h * 0.5),
                radius: w * 0.34,
                startAngle: .degrees(150),
                endAngle: .degrees(330),
                clockwise: false
            )
            context.stroke(topArc, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth * 0.95, lineCap: .round))

            // 上箭头尖端
            var topHead = Path()
            topHead.move(to: CGPoint(x: w * 0.72, y: h * 0.28))
            topHead.addLine(to: CGPoint(x: w * 0.80, y: h * 0.35))
            topHead.addLine(to: CGPoint(x: w * 0.72, y: h * 0.42))
            context.stroke(topHead, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth * 0.95, lineCap: .round, lineJoin: .round))

            // 2. 下弧形出袋箭头 (模拟 3D 霓虹绿拔出弧线)
            var bottomArc = Path()
            bottomArc.addArc(
                center: CGPoint(x: w * 0.5, y: h * 0.5),
                radius: w * 0.34,
                startAngle: .degrees(330),
                endAngle: .degrees(150),
                clockwise: false
            )
            context.stroke(bottomArc, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth * 0.95, lineCap: .round))

            // 下箭头尖端
            var bottomHead = Path()
            bottomHead.move(to: CGPoint(x: w * 0.28, y: h * 0.72))
            bottomHead.addLine(to: CGPoint(x: w * 0.20, y: h * 0.65))
            bottomHead.addLine(to: CGPoint(x: w * 0.28, y: h * 0.58))
            context.stroke(bottomHead, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth * 0.95, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - 8. 成功状态 (StatusSuccess)
    private var statusSuccessIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 成功外环 (面 + 线)
            let circleRect = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.76, height: h * 0.76)
            let circlePath = Path(ellipseIn: circleRect)
            context.fill(circlePath, with: .color(primaryTint.opacity(0.18)))
            context.stroke(circlePath, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            // 对勾
            var check = Path()
            check.move(to: CGPoint(x: w * 0.32, y: h * 0.50))
            check.addLine(to: CGPoint(x: w * 0.46, y: h * 0.65))
            check.addLine(to: CGPoint(x: w * 0.70, y: h * 0.36))
            context.stroke(check, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth * 1.2, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - 9. 警告状态 (StatusWarning)
    private var statusWarningIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 柔和圆角三角形
            var tri = Path()
            tri.move(to: CGPoint(x: w * 0.5, y: h * 0.14))
            tri.addLine(to: CGPoint(x: w * 0.86, y: h * 0.82))
            tri.addLine(to: CGPoint(x: w * 0.14, y: h * 0.82))
            tri.closeSubpath()
            context.fill(tri, with: .color(primaryTint.opacity(0.2)))
            context.stroke(tri, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 感叹号
            var mark = Path()
            mark.move(to: CGPoint(x: w * 0.5, y: h * 0.38))
            mark.addLine(to: CGPoint(x: w * 0.5, y: h * 0.58))
            context.stroke(mark, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth * 1.1, lineCap: .round))

            let dotRect = CGRect(x: w * 0.46, y: h * 0.68, width: w * 0.08, height: w * 0.08)
            context.fill(Path(ellipseIn: dotRect), with: .color(primaryTint))
        }
    }

    // MARK: - 10. 失败 / 错误 (StatusError)
    private var statusErrorIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            let circleRect = CGRect(x: w * 0.12, y: h * 0.12, width: w * 0.76, height: h * 0.76)
            let circlePath = Path(ellipseIn: circleRect)
            context.fill(circlePath, with: .color(primaryTint.opacity(0.18)))
            context.stroke(circlePath, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            // X 叉号
            var cross = Path()
            cross.move(to: CGPoint(x: w * 0.35, y: h * 0.35))
            cross.addLine(to: CGPoint(x: w * 0.65, y: h * 0.65))
            cross.move(to: CGPoint(x: w * 0.65, y: h * 0.35))
            cross.addLine(to: CGPoint(x: w * 0.35, y: h * 0.65))
            context.stroke(cross, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth * 1.1, lineCap: .round))
        }
    }

    // MARK: - 11. 通用文档 (FileGeneric)
    private var fileGenericIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 具有折角的文档
            var doc = Path()
            doc.move(to: CGPoint(x: w * 0.22, y: h * 0.14))
            doc.addLine(to: CGPoint(x: w * 0.58, y: h * 0.14))
            doc.addLine(to: CGPoint(x: w * 0.78, y: h * 0.34))
            doc.addLine(to: CGPoint(x: w * 0.78, y: h * 0.86))
            doc.addLine(to: CGPoint(x: w * 0.22, y: h * 0.86))
            doc.closeSubpath()
            context.fill(doc, with: .color(primaryTint.opacity(0.15)))
            context.stroke(doc, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 折角三角形
            var fold = Path()
            fold.move(to: CGPoint(x: w * 0.58, y: h * 0.14))
            fold.addLine(to: CGPoint(x: w * 0.58, y: h * 0.34))
            fold.addLine(to: CGPoint(x: w * 0.78, y: h * 0.34))
            context.stroke(fold, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - 12. 预览之眼 (PreviewEye)
    private var previewEyeIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 杏眼轮廓
            var eye = Path()
            eye.move(to: CGPoint(x: w * 0.14, y: h * 0.5))
            eye.addQuadCurve(to: CGPoint(x: w * 0.86, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.18))
            eye.addQuadCurve(to: CGPoint(x: w * 0.14, y: h * 0.5), control: CGPoint(x: w * 0.5, y: h * 0.82))
            context.fill(eye, with: .color(primaryTint.opacity(0.12)))
            context.stroke(eye, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 瞳孔高光
            let irisRect = CGRect(x: w * 0.38, y: h * 0.38, width: w * 0.24, height: h * 0.24)
            context.fill(Path(ellipseIn: irisRect), with: .color(secondaryTint))
        }
    }

    // MARK: - 13. 清除 / 纸篓 (TrashClean)
    private var trashCleanIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 桶体
            var bin = Path()
            bin.move(to: CGPoint(x: w * 0.25, y: h * 0.32))
            bin.addLine(to: CGPoint(x: w * 0.30, y: h * 0.82))
            bin.addLine(to: CGPoint(x: w * 0.70, y: h * 0.82))
            bin.addLine(to: CGPoint(x: w * 0.75, y: h * 0.32))
            context.stroke(bin, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 顶盖
            var lid = Path()
            lid.move(to: CGPoint(x: w * 0.18, y: h * 0.32))
            lid.addLine(to: CGPoint(x: w * 0.82, y: h * 0.32))
            lid.move(to: CGPoint(x: w * 0.40, y: h * 0.32))
            lid.addLine(to: CGPoint(x: w * 0.40, y: h * 0.22))
            lid.addLine(to: CGPoint(x: w * 0.60, y: h * 0.22))
            lid.addLine(to: CGPoint(x: w * 0.60, y: h * 0.32))
            context.stroke(lid, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - 14. 访达雷达定位 (FinderReveal)
    private var finderRevealIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            let frameRect = CGRect(x: w * 0.18, y: h * 0.18, width: w * 0.64, height: h * 0.64)
            context.stroke(Path(roundedRect: frameRect, cornerRadius: 4), with: .color(primaryTint.opacity(0.35)), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            // 外推定位斜向箭头
            var arrow = Path()
            arrow.move(to: CGPoint(x: w * 0.40, y: h * 0.60))
            arrow.addLine(to: CGPoint(x: w * 0.75, y: h * 0.25))
            arrow.move(to: CGPoint(x: w * 0.54, y: h * 0.25))
            arrow.addLine(to: CGPoint(x: w * 0.75, y: h * 0.25))
            arrow.addLine(to: CGPoint(x: w * 0.75, y: h * 0.46))
            context.stroke(arrow, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth * 1.1, lineCap: .round, lineJoin: .round))
        }
    }

    // MARK: - 15. 全生态认证勋章 (BadgeSeal)
    private var badgeSealIcon: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height

            // 锯齿勋章轮廓
            let center = CGPoint(x: w * 0.5, y: h * 0.5)
            let points = 12
            let rOuter = w * 0.40
            let rInner = w * 0.32
            var star = Path()
            for i in 0..<(points * 2) {
                let angle = Double(i) * .pi / Double(points)
                let r = (i % 2 == 0) ? rOuter : rInner
                let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
                if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
            }
            star.closeSubpath()
            context.fill(star, with: .color(primaryTint.opacity(0.2)))
            context.stroke(star, with: .color(primaryTint), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round))

            // 内部小对勾
            var check = Path()
            check.move(to: CGPoint(x: w * 0.38, y: h * 0.52))
            check.addLine(to: CGPoint(x: w * 0.48, y: h * 0.62))
            check.addLine(to: CGPoint(x: w * 0.64, y: h * 0.40))
            context.stroke(check, with: .color(secondaryTint), style: StrokeStyle(lineWidth: strokeWidth * 1.1, lineCap: .round, lineJoin: .round))
        }
    }
}
