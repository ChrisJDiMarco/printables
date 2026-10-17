import SwiftUI

enum MascotMood {
    case waving
    case thinking
    case celebrating
    case sleeping
    case curious
}

struct Mascot: View {
    let mood: MascotMood
    var size: CGFloat = 120
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floatPhase: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.sun.opacity(0.22))
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 4)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.sun, AppTheme.sunSoft],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Circle().strokeBorder(.white.opacity(0.6), lineWidth: 3)
                    )

                cheeks
                eyes
                mouth

                if mood == .celebrating {
                    sparkles
                }
                if mood == .thinking {
                    Image(systemName: "questionmark")
                        .font(.system(size: size * 0.18, weight: .heavy))
                        .foregroundStyle(AppTheme.coral)
                        .offset(x: size * 0.36, y: -size * 0.42)
                }
                if mood == .sleeping {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: size * 0.18, weight: .heavy))
                        .foregroundStyle(AppTheme.lilac)
                        .offset(x: size * 0.36, y: -size * 0.42)
                }
            }
            .frame(width: size, height: size)
            .offset(y: reduceMotion ? 0 : sin(floatPhase) * 4)
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                floatPhase = .pi
            }
        }
    }

    private var cheeks: some View {
        HStack(spacing: size * 0.42) {
            Circle()
                .fill(AppTheme.coral.opacity(0.45))
                .frame(width: size * 0.16, height: size * 0.10)
            Circle()
                .fill(AppTheme.coral.opacity(0.45))
                .frame(width: size * 0.16, height: size * 0.10)
        }
        .offset(y: size * 0.10)
    }

    private var eyes: some View {
        HStack(spacing: size * 0.30) {
            eye
            eye
        }
        .offset(y: -size * 0.04)
    }

    private var eye: some View {
        Capsule()
            .fill(AppTheme.ink)
            .frame(width: size * 0.07, height: mood == .sleeping ? size * 0.025 : size * 0.13)
    }

    @ViewBuilder
    private var mouth: some View {
        switch mood {
        case .celebrating:
            Capsule()
                .fill(AppTheme.ink)
                .frame(width: size * 0.22, height: size * 0.12)
                .offset(y: size * 0.18)
        case .thinking, .sleeping:
            Capsule()
                .fill(AppTheme.ink)
                .frame(width: size * 0.10, height: size * 0.03)
                .offset(y: size * 0.20)
        case .waving, .curious:
            ZStack {
                Capsule()
                    .fill(AppTheme.ink)
                    .frame(width: size * 0.18, height: size * 0.06)
            }
            .offset(y: size * 0.18)
        }
    }

    private var sparkles: some View {
        ZStack {
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.18, weight: .heavy))
                .foregroundStyle(AppTheme.coral)
                .offset(x: -size * 0.5, y: -size * 0.42)
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.14, weight: .heavy))
                .foregroundStyle(AppTheme.sky)
                .offset(x: size * 0.5, y: -size * 0.30)
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.12, weight: .heavy))
                .foregroundStyle(AppTheme.mint)
                .offset(x: size * 0.45, y: size * 0.35)
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        Mascot(mood: .waving)
        Mascot(mood: .thinking)
        Mascot(mood: .celebrating)
        Mascot(mood: .sleeping)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(AppTheme.cream)
}
