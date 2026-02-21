import SwiftUI

enum CenterContentType: Sendable {
    case text(String)
    case image(URL)
    case sfSymbol(String)
}

struct CenterContent: Sendable {
    let content: CenterContentType
    let color: Color
    let sizeRatio: CGFloat  // 0.0 to 1.0, relative to icon size
}

struct SquircleView: View {
    let backgroundColor: Color
    let size: CGFloat
    let cornerRadiusRatio: CGFloat
    let labels: [IconLabel]
    let centerContent: CenterContent?

    init(
        backgroundColor: Color,
        size: CGFloat,
        cornerRadiusRatio: CGFloat,
        labels: [IconLabel] = [],
        centerContent: CenterContent? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.size = size
        self.cornerRadiusRatio = cornerRadiusRatio
        self.labels = labels
        self.centerContent = centerContent
    }

    private let centerContentID = "centerContent"

    var body: some View {
        Canvas { context, canvasSize in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let cornerRadius = min(canvasSize.width, canvasSize.height) * cornerRadiusRatio
            let squirclePath = Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)

            // Fill background
            context.fill(squirclePath, with: .color(backgroundColor))

            // Draw center content (before clipping so it's not affected by label clip)
            if centerContent != nil, let symbol = context.resolveSymbol(id: centerContentID) {
                context.draw(symbol, at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2))
            }

            // Clip all subsequent drawing to the squircle
            context.clip(to: squirclePath)

            // Draw each label
            for label in labels {
                drawLabel(label, in: context, canvasSize: canvasSize)
            }
        } symbols: {
            // Center content symbol
            if let center = centerContent {
                centerContentView(for: center)
                    .tag(centerContentID)
            }

            // Create symbols for each label's content
            ForEach(labels) { label in
                labelContentView(for: label)
                    .tag(label.id)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func centerContentView(for center: CenterContent) -> some View {
        let contentSize = size * center.sizeRatio
        switch center.content {
        case .text(let text):
            Text(text)
                .font(.system(size: contentSize, weight: .bold))
                .foregroundStyle(center.color)
        case .image(let url):
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: contentSize, height: contentSize)
            }
        case .sfSymbol(let name):
            Image(systemName: name)
                .font(.system(size: contentSize, weight: .bold))
                .foregroundStyle(center.color)
        }
    }

    @ViewBuilder
    private func labelContentView(for label: IconLabel) -> some View {
        switch label.content {
        case .text(let text):
            Text(text)
                .font(.system(size: size * 0.08, weight: .bold))
                .foregroundStyle(label.foregroundColor)
        case .image(let url):
            if let nsImage = NSImage(contentsOf: url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: size * 0.1)
                    .foregroundStyle(label.foregroundColor)
            }
        case .sfSymbol(let name):
            Image(systemName: name)
                .font(.system(size: size * 0.08, weight: .bold))
                .foregroundStyle(label.foregroundColor)
        }
    }

    private func drawLabel(_ label: IconLabel, in context: GraphicsContext, canvasSize: CGSize) {
        let ribbonThickness = canvasSize.height * 0.15
        let pillHeight = canvasSize.height * 0.12
        let pillPadding = canvasSize.width * 0.05
        let diagonalWidth = canvasSize.width * 0.35

        switch label.position {
        // Edge ribbons
        case .top:
            let rect = CGRect(x: 0, y: 0, width: canvasSize.width, height: ribbonThickness)
            context.fill(Path(rect), with: .color(label.backgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                context.draw(symbol, at: CGPoint(x: canvasSize.width / 2, y: ribbonThickness / 2))
            }

        case .bottom:
            let rect = CGRect(x: 0, y: canvasSize.height - ribbonThickness, width: canvasSize.width, height: ribbonThickness)
            context.fill(Path(rect), with: .color(label.backgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                context.draw(symbol, at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height - ribbonThickness / 2))
            }

        case .left:
            let rect = CGRect(x: 0, y: 0, width: ribbonThickness, height: canvasSize.height)
            context.fill(Path(rect), with: .color(label.backgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                var rotatedContext = context
                rotatedContext.rotate(by: .degrees(-90))
                rotatedContext.draw(symbol, at: CGPoint(x: -canvasSize.height / 2, y: ribbonThickness / 2))
            }

        case .right:
            let rect = CGRect(x: canvasSize.width - ribbonThickness, y: 0, width: ribbonThickness, height: canvasSize.height)
            context.fill(Path(rect), with: .color(label.backgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                var rotatedContext = context
                rotatedContext.rotate(by: .degrees(90))
                rotatedContext.draw(symbol, at: CGPoint(x: canvasSize.height / 2, y: -canvasSize.width + ribbonThickness / 2))
            }

        // Diagonal corner ribbons
        case .topLeft:
            let path = diagonalRibbonPath(corner: .topLeft, size: canvasSize, width: diagonalWidth)
            context.fill(path, with: .color(label.backgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                // Centroid of triangle at (0,0), (w,0), (0,w) is (w/3, w/3)
                let centroid = CGPoint(x: diagonalWidth / 3, y: diagonalWidth / 3)
                var rotatedContext = context
                rotatedContext.translateBy(x: centroid.x, y: centroid.y)
                rotatedContext.rotate(by: .degrees(-45))
                rotatedContext.draw(symbol, at: .zero)
            }

        case .topRight:
            let path = diagonalRibbonPath(corner: .topRight, size: canvasSize, width: diagonalWidth)
            context.fill(path, with: .color(label.backgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                // Centroid of triangle at (w,0), (w-d,0), (w,d)
                let centroid = CGPoint(
                    x: canvasSize.width - diagonalWidth / 3,
                    y: diagonalWidth / 3
                )
                var rotatedContext = context
                rotatedContext.translateBy(x: centroid.x, y: centroid.y)
                rotatedContext.rotate(by: .degrees(45))
                rotatedContext.draw(symbol, at: .zero)
            }

        case .bottomLeft:
            let path = diagonalRibbonPath(corner: .bottomLeft, size: canvasSize, width: diagonalWidth)
            context.fill(path, with: .color(label.backgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                // Centroid of triangle at (0,h), (d,h), (0,h-d)
                let centroid = CGPoint(
                    x: diagonalWidth / 3,
                    y: canvasSize.height - diagonalWidth / 3
                )
                var rotatedContext = context
                rotatedContext.translateBy(x: centroid.x, y: centroid.y)
                rotatedContext.rotate(by: .degrees(45))
                rotatedContext.draw(symbol, at: .zero)
            }

        case .bottomRight:
            let path = diagonalRibbonPath(corner: .bottomRight, size: canvasSize, width: diagonalWidth)
            context.fill(path, with: .color(label.backgroundColor))
            if let symbol = context.resolveSymbol(id: label.id) {
                // Centroid of triangle at (w,h), (w-d,h), (w,h-d)
                let centroid = CGPoint(
                    x: canvasSize.width - diagonalWidth / 3,
                    y: canvasSize.height - diagonalWidth / 3
                )
                var rotatedContext = context
                rotatedContext.translateBy(x: centroid.x, y: centroid.y)
                rotatedContext.rotate(by: .degrees(-45))
                rotatedContext.draw(symbol, at: .zero)
            }

        // Pill overlays
        case .pillLeft:
            if let symbol = context.resolveSymbol(id: label.id) {
                let symbolSize = symbol.size
                let pillWidth = symbolSize.width + pillPadding * 2
                let pillRect = CGRect(
                    x: pillPadding,
                    y: canvasSize.height - pillHeight - pillPadding,
                    width: pillWidth,
                    height: pillHeight
                )
                let pillPath = Path(roundedRect: pillRect, cornerRadius: pillHeight / 2)
                context.fill(pillPath, with: .color(label.backgroundColor))
                context.draw(symbol, at: CGPoint(x: pillRect.midX, y: pillRect.midY))
            }

        case .pillCenter:
            if let symbol = context.resolveSymbol(id: label.id) {
                let symbolSize = symbol.size
                let pillWidth = symbolSize.width + pillPadding * 2
                let pillRect = CGRect(
                    x: (canvasSize.width - pillWidth) / 2,
                    y: canvasSize.height - pillHeight - pillPadding,
                    width: pillWidth,
                    height: pillHeight
                )
                let pillPath = Path(roundedRect: pillRect, cornerRadius: pillHeight / 2)
                context.fill(pillPath, with: .color(label.backgroundColor))
                context.draw(symbol, at: CGPoint(x: pillRect.midX, y: pillRect.midY))
            }

        case .pillRight:
            if let symbol = context.resolveSymbol(id: label.id) {
                let symbolSize = symbol.size
                let pillWidth = symbolSize.width + pillPadding * 2
                let pillRect = CGRect(
                    x: canvasSize.width - pillWidth - pillPadding,
                    y: canvasSize.height - pillHeight - pillPadding,
                    width: pillWidth,
                    height: pillHeight
                )
                let pillPath = Path(roundedRect: pillRect, cornerRadius: pillHeight / 2)
                context.fill(pillPath, with: .color(label.backgroundColor))
                context.draw(symbol, at: CGPoint(x: pillRect.midX, y: pillRect.midY))
            }
        }
    }

    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func diagonalRibbonPath(corner: Corner, size: CGSize, width: CGFloat) -> Path {
        var path = Path()

        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width, y: 0))
            path.addLine(to: CGPoint(x: 0, y: width))
            path.closeSubpath()

        case .topRight:
            path.move(to: CGPoint(x: size.width, y: 0))
            path.addLine(to: CGPoint(x: size.width - width, y: 0))
            path.addLine(to: CGPoint(x: size.width, y: width))
            path.closeSubpath()

        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: width, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height - width))
            path.closeSubpath()

        case .bottomRight:
            path.move(to: CGPoint(x: size.width, y: size.height))
            path.addLine(to: CGPoint(x: size.width - width, y: size.height))
            path.addLine(to: CGPoint(x: size.width, y: size.height - width))
            path.closeSubpath()
        }

        return path
    }
}
