import SwiftUI

struct IdeaChip: View {
    let title: String
    var icon: String?
    var color: Color = AppTheme.sun
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(color)
                        .clipShape(Circle())
                }
                Text(title)
                    .font(AppTheme.roundedBody(13, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.18), color.opacity(0.10)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(color.opacity(0.30), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.18), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.scaled(haptic: .selection))
        .accessibilityLabel("Use suggestion: \(title)")
    }
}

#Preview {
    ZStack {
        AppTheme.cream
        VStack(spacing: 12) {
            IdeaChip(title: "Letter sounds and tracing", icon: "textformat.abc", color: AppTheme.coral) {}
            IdeaChip(title: "Counting and colors", icon: "1.circle.fill", color: AppTheme.sky) {}
            IdeaChip(title: "Healthy eating", icon: "leaf.fill", color: AppTheme.mint) {}
        }
    }
    .frame(width: 360, height: 280)
}
