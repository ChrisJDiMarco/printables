import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let background: Color
    let foreground: Color
    let isLoading: Bool
    let haptic: HapticFeel?
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        background: Color = AppTheme.coral,
        foreground: Color = .white,
        isLoading: Bool = false,
        haptic: HapticFeel? = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.background = background
        self.foreground = foreground
        self.isLoading = isLoading
        self.haptic = haptic
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(foreground)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(AppTheme.roundedBody(17, weight: .heavy))
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(foreground)
            .background(
                LinearGradient(
                    colors: [background, background.opacity(0.86)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: background.opacity(0.30), radius: 14, x: 0, y: 7)
        }
        .buttonStyle(.scaled(haptic: haptic))
        .disabled(isLoading)
        .opacity(isLoading ? 0.75 : 1)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

struct SecondaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(AppTheme.roundedBody(15, weight: .heavy))
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(AppTheme.ink)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerSmall, style: .continuous)
                    .strokeBorder(AppTheme.ink.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.scaled(haptic: .light))
        .accessibilityAddTraits(.isButton)
    }
}

struct TertiaryButton: View {
    let title: String
    let systemImage: String?
    let tint: Color
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        tint: Color = AppTheme.coral,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .heavy))
                }
                Text(title)
                    .font(AppTheme.roundedBody(13, weight: .heavy))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
        }
        .buttonStyle(.scaled(haptic: .light))
        .accessibilityAddTraits(.isButton)
    }
}
