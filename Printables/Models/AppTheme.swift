import SwiftUI

enum AppTheme {
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.86)
    static let creamDeep = Color(red: 0.99, green: 0.95, blue: 0.80)
    static let coral = Color(red: 0.91, green: 0.36, blue: 0.36)
    static let coralSoft = Color(red: 0.94, green: 0.55, blue: 0.55)
    static let sky = Color(red: 0.20, green: 0.60, blue: 0.83)
    static let skySoft = Color(red: 0.43, green: 0.74, blue: 0.91)
    static let sun = Color(red: 1.00, green: 0.82, blue: 0.32)
    static let sunSoft = Color(red: 1.00, green: 0.89, blue: 0.51)
    static let mint = Color(red: 0.50, green: 0.83, blue: 0.67)
    static let lilac = Color(red: 0.76, green: 0.70, blue: 0.92)
    static let ink = Color(red: 0.12, green: 0.13, blue: 0.18)
    static let inkSoft = Color(red: 0.32, green: 0.33, blue: 0.40)
    static let paper = Color.white

    static let cornerLarge: CGFloat = 28
    static let cornerMedium: CGFloat = 20
    static let cornerSmall: CGFloat = 12

    static func roundedTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func roundedBody(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct CreamBackground: View {
    var showDots: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.cream, AppTheme.creamDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if showDots {
                DecorativeDots()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

struct DecorativeDots: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Self.dots, id: \.id) { dot in
                    Circle()
                        .fill(dot.color)
                        .frame(width: dot.size, height: dot.size)
                        .position(
                            x: dot.xRatio * geo.size.width,
                            y: dot.yRatio * geo.size.height
                        )
                        .opacity(0.58)
                }
            }
        }
    }

    private struct Dot {
        let id = UUID()
        let xRatio: CGFloat
        let yRatio: CGFloat
        let size: CGFloat
        let color: Color
    }

    private static let dots: [Dot] = [
        Dot(xRatio: 0.08, yRatio: 0.04, size: 18, color: AppTheme.sun),
        Dot(xRatio: 0.95, yRatio: 0.06, size: 14, color: AppTheme.sun),
        Dot(xRatio: 0.20, yRatio: 0.12, size: 10, color: AppTheme.coralSoft),
        Dot(xRatio: 0.78, yRatio: 0.10, size: 12, color: AppTheme.coralSoft),
        Dot(xRatio: 0.05, yRatio: 0.32, size: 12, color: AppTheme.skySoft),
        Dot(xRatio: 0.92, yRatio: 0.30, size: 16, color: AppTheme.sun),
        Dot(xRatio: 0.50, yRatio: 0.27, size: 8, color: AppTheme.skySoft),
        Dot(xRatio: 0.15, yRatio: 0.55, size: 16, color: AppTheme.sun),
        Dot(xRatio: 0.88, yRatio: 0.58, size: 10, color: AppTheme.coralSoft),
        Dot(xRatio: 0.32, yRatio: 0.74, size: 10, color: AppTheme.skySoft),
        Dot(xRatio: 0.70, yRatio: 0.78, size: 14, color: AppTheme.sun),
        Dot(xRatio: 0.10, yRatio: 0.88, size: 16, color: AppTheme.coralSoft),
        Dot(xRatio: 0.92, yRatio: 0.92, size: 12, color: AppTheme.sun),
        Dot(xRatio: 0.55, yRatio: 0.95, size: 10, color: AppTheme.skySoft)
    ]
}
