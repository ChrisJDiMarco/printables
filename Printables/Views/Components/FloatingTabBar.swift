import SwiftUI

enum AppTab: Hashable, CaseIterable {
    case library
    case create
    case settings

    var label: String {
        switch self {
        case .library: return "Library"
        case .create: return "Create"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .library: return "books.vertical.fill"
        case .create: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selection: AppTab

    @Namespace private var indicatorNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.library)
            createButton
            tabButton(.settings)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.regularMaterial)
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.85))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .strokeBorder(AppTheme.ink.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: AppTheme.ink.opacity(0.14), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 22)
        .padding(.bottom, 6)
        .accessibilityElement(children: .contain)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            select(tab)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .symbolEffect(.bounce, value: selection == tab)
                Text(tab.label)
                    .font(AppTheme.roundedBody(10, weight: .heavy))
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(selection == tab ? AppTheme.coral : AppTheme.inkSoft.opacity(0.7))
            .padding(.vertical, 6)
            .background(
                ZStack {
                    if selection == tab {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.coral.opacity(0.10))
                            .matchedGeometryEffect(id: "indicator", in: indicatorNamespace)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(selection == tab ? .isSelected : [])
    }

    private var createButton: some View {
        Button {
            select(.create)
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.coral.opacity(0.14))
                    .frame(width: 58, height: 58)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.coral, AppTheme.coral.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: AppTheme.coral.opacity(0.45), radius: 10, x: 0, y: 5)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .scaleEffect(selection == .create ? 1.0 : 0.95)
                    .animation(
                        reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.65),
                        value: selection == .create
                    )
            }
            .frame(maxWidth: .infinity)
            .offset(y: -6)
            .accessibilityLabel("Create new worksheet")
            .accessibilityAddTraits(.isButton)
        }
        .buttonStyle(.scaled(haptic: nil))
    }

    private func select(_ tab: AppTab) {
        if selection != tab {
            Haptics.shared.play(.selection)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.75)) {
                selection = tab
            }
        }
    }
}
