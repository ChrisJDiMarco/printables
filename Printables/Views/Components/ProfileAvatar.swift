import SwiftUI

struct ProfileAvatar: View {
    let profile: ChildProfile
    var size: CGFloat = 36
    var showRing: Bool = false

    var body: some View {
        Group {
            if profile.hasName {
                filledAvatar
            } else {
                placeholderAvatar
            }
        }
        .padding(showRing ? 3 : 0)
        .background(
            Circle()
                .stroke(showRing ? profile.color.swiftUIColor : Color.clear, lineWidth: 2)
        )
        .accessibilityHidden(true)
    }

    private var filledAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            profile.color.swiftUIColor,
                            profile.color.swiftUIColor.opacity(0.78)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle().strokeBorder(.white.opacity(0.5), lineWidth: max(1, size * 0.05))
                )

            Text(profile.initial)
                .font(.system(size: size * 0.44, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var placeholderAvatar: some View {
        ZStack {
            Circle()
                .fill(AppTheme.creamDeep)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(
                            AppTheme.coral.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                        )
                )

            Image(systemName: "plus")
                .font(.system(size: size * 0.36, weight: .heavy))
                .foregroundStyle(AppTheme.coral)
        }
    }
}

struct ProfileSwitcherPill: View {
    let profile: ChildProfile
    let totalProfiles: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ProfileAvatar(profile: profile, size: 30)
                VStack(alignment: .leading, spacing: 0) {
                    Text(displayName)
                        .font(AppTheme.roundedBody(13, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                    Text(profile.ageRange.label)
                        .font(AppTheme.roundedBody(10, weight: .heavy))
                        .foregroundStyle(AppTheme.inkSoft)
                }
                if totalProfiles > 1 {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(AppTheme.inkSoft)
                        .padding(.leading, 2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .padding(.trailing, totalProfiles > 1 ? 6 : 10)
            .background(.white)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(AppTheme.ink.opacity(0.06), lineWidth: 1))
            .shadow(color: AppTheme.ink.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.scaled(haptic: .light))
        .accessibilityLabel("Active learner: \(displayName), \(profile.ageRange.label). Tap to switch.")
    }

    private var displayName: String {
        profile.hasName ? profile.greetingName : "Set up"
    }
}

struct AddLearnerPill: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add learner")
                    .font(AppTheme.roundedBody(13, weight: .heavy))
            }
            .foregroundStyle(AppTheme.coral)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white)
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(AppTheme.coral.opacity(0.25), lineWidth: 1))
            .shadow(color: AppTheme.coral.opacity(0.10), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.scaled(haptic: .light))
        .accessibilityLabel("Add a learner profile")
    }
}
