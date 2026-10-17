import SwiftUI

struct ConfettiView: View {
    var palette: [Color] = [AppTheme.coral, AppTheme.sky, AppTheme.sun, AppTheme.mint, AppTheme.lilac]
    var pieceCount: Int = 90
    var trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            EmptyView()
        } else {
            ZStack {
                ForEach(0..<pieceCount, id: \.self) { idx in
                    ConfettiPiece(
                        color: palette[idx % palette.count],
                        index: idx,
                        total: pieceCount,
                        trigger: trigger
                    )
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

private struct ConfettiPiece: View {
    let color: Color
    let index: Int
    let total: Int
    let trigger: Int

    @State private var startX: CGFloat = 0
    @State private var startY: CGFloat = -120
    @State private var endX: CGFloat = 0
    @State private var endY: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var spin: Double = 0
    @State private var size: CGFloat = 8
    @State private var shape: PieceShape = .rect
    @State private var animate: Bool = false

    enum PieceShape: Int {
        case rect, circle, capsule, triangle
    }

    var body: some View {
        GeometryReader { proxy in
            let containerWidth = proxy.size.width
            let containerHeight = proxy.size.height
            let halfWidth = containerWidth / 2
            let resolvedEndX = halfWidth + endX
            let resolvedEndY = endY + containerHeight
            let startPoint = CGPoint(x: halfWidth + startX, y: startY)
            let endPoint = CGPoint(x: resolvedEndX, y: resolvedEndY)
            let currentPoint = animate ? endPoint : startPoint

            shapeView
                .frame(width: size, height: size * 0.6)
                .rotationEffect(.degrees(animate ? rotation + spin : rotation))
                .position(currentPoint)
                .opacity(animate ? 0 : 1)
        }
        .onAppear { configure() }
        .onChange(of: trigger) { _, _ in
            configure()
        }
    }

    @ViewBuilder
    private var shapeView: some View {
        switch shape {
        case .rect:
            RoundedRectangle(cornerRadius: 2, style: .continuous).fill(color)
        case .circle:
            Circle().fill(color)
        case .capsule:
            Capsule().fill(color)
        case .triangle:
            Triangle().fill(color)
        }
    }

    private func configure() {
        animate = false
        size = CGFloat.random(in: 6...14)
        startX = CGFloat.random(in: -60...60)
        startY = -CGFloat.random(in: 40...160)
        endX = CGFloat.random(in: -220...220)
        endY = CGFloat.random(in: 200...420)
        rotation = Double.random(in: 0...360)
        spin = Double.random(in: 360...720) * (Bool.random() ? 1 : -1)
        shape = PieceShape(rawValue: Int.random(in: 0..<4)) ?? .rect

        let duration = Double.random(in: 1.6...2.6)
        let delay = Double(index) * 0.012
        withAnimation(.easeOut(duration: duration).delay(delay)) {
            animate = true
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
