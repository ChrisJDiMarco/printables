import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var childName: String = ""
    @State private var selectedAge: AgeRange = .four_six
    @State private var selectedColor: ProfileColor = .coral
    @FocusState private var nameFocused: Bool

    private let totalPages = 4

    var body: some View {
        ZStack {
            CreamBackground()
            VStack(spacing: 18) {
                topBar
                Spacer(minLength: 0)
                pageContent
                Spacer(minLength: 0)
                progressDots
                bottomButton
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            if let first = settings.profiles.first {
                childName = first.name
                selectedAge = first.ageRange
                selectedColor = first.color
            }
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page {
        case 0:
            page1Snap
        case 1:
            page2Teach
        case 2:
            page3Print
        case 3:
            page4Profile
        default:
            EmptyView()
        }
    }

    private var topBar: some View {
        HStack {
            if page > 0 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        page -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)
                        .frame(width: 40, height: 40)
                        .background(.white)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(AppTheme.ink.opacity(0.06), lineWidth: 1))
                }
                .buttonStyle(.scaled(haptic: .light))
            }
            Spacer()
            if page < totalPages - 1 {
                Button("Skip") {
                    finish()
                }
                .font(AppTheme.roundedBody(14, weight: .heavy))
                .foregroundStyle(AppTheme.inkSoft)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(height: 56)
    }

    private var page1Snap: some View {
        VStack(spacing: 22) {
            PhotoToWorksheetHero()

            VStack(spacing: 10) {
                Text("Snap anything")
                    .font(AppTheme.roundedTitle(30))
                    .foregroundStyle(AppTheme.ink)
                Text("Turn the little things around the house into print-ready learning pages.")
                    .font(AppTheme.roundedBody(16, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 32)
            }
        }
    }

    private var page2Teach: some View {
        OnboardingPageView(
            iconBackdropColor: AppTheme.sky,
            icon: "wand.and.stars",
            title: "Tell us what to teach",
            subtitle: "Letters, counting, safety, colors. We'll design the perfect page."
        )
    }

    private var page3Print: some View {
        OnboardingPageView(
            iconBackdropColor: AppTheme.sun,
            icon: "printer.fill",
            title: "Print, share, learn",
            subtitle: "Beautiful printables made for little hands and curious minds."
        )
    }

    private var page4Profile: some View {
        VStack(spacing: 22) {
            Mascot(mood: .waving, size: 140)

            VStack(spacing: 8) {
                Text("Who are we making for?")
                    .font(AppTheme.roundedTitle(26))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)
                Text("This helps us match the activities to your child's age.")
                    .font(AppTheme.roundedBody(14, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Child's name (optional)")
                    .font(AppTheme.roundedBody(13, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)

                TextField("First name", text: $childName)
                    .focused($nameFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .font(AppTheme.roundedBody(15, weight: .medium))
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(nameFocused ? AppTheme.coral.opacity(0.4) : AppTheme.ink.opacity(0.06), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 10) {
                Text("Age")
                    .font(AppTheme.roundedBody(13, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                ageGrid
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 10) {
                Text("Color")
                    .font(AppTheme.roundedBody(13, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                HStack(spacing: 12) {
                    ForEach(ProfileColor.allCases) { c in
                        Button {
                            Haptics.shared.play(.selection)
                            selectedColor = c
                        } label: {
                            Circle()
                                .fill(c.swiftUIColor)
                                .frame(width: 34, height: 34)
                                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                                .overlay(
                                    Circle().strokeBorder(selectedColor == c ? AppTheme.ink : Color.clear, lineWidth: 2).padding(-4)
                                )
                        }
                        .buttonStyle(.scaled(haptic: nil))
                        .accessibilityLabel("\(c.displayName) color")
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var ageGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            ForEach(AgeRange.allCases) { range in
                Button {
                    Haptics.shared.play(.selection)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedAge = range
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(range.emoji)
                            .font(.system(size: 18))
                        Text(range.label)
                            .font(AppTheme.roundedBody(14, weight: .heavy))
                        Spacer()
                        if selectedAge == range {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.coral)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(AppTheme.ink)
                    .background(selectedAge == range ? AppTheme.coral.opacity(0.08) : .white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                selectedAge == range ? AppTheme.coral : AppTheme.ink.opacity(0.06),
                                lineWidth: selectedAge == range ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.scaled(haptic: nil))
            }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { idx in
                Capsule()
                    .fill(idx == page ? AppTheme.coral : AppTheme.coral.opacity(0.2))
                    .frame(width: idx == page ? 24 : 8, height: 8)
                    .animation(.easeInOut, value: page)
            }
        }
    }

    private var bottomButton: some View {
        PrimaryButton(
            page == totalPages - 1 ? "Let's go" : "Next",
            systemImage: page == totalPages - 1 ? "sparkles" : nil,
            haptic: .medium
        ) {
            if page < totalPages - 1 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    page += 1
                }
            } else {
                finish()
            }
        }
    }

    private func finish() {
        if settings.profiles.isEmpty {
            let added = settings.addProfile(name: childName, ageRange: selectedAge, color: selectedColor)
            settings.setActive(added)
        } else if var existing = settings.profiles.first {
            existing.name = childName
            existing.ageRange = selectedAge
            existing.colorRaw = selectedColor.rawValue
            settings.updateProfile(existing)
            settings.setActive(existing)
        }
        settings.onboardingCompleted = true
        Haptics.shared.play(.success)
        dismiss()
    }
}

struct OnboardingPageView: View {
    let iconBackdropColor: Color
    let icon: String
    let title: String
    let subtitle: String

    @State private var animateIn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(iconBackdropColor.opacity(0.18))
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateIn || reduceMotion ? 1 : 0.6)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [iconBackdropColor, iconBackdropColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: iconBackdropColor.opacity(0.45), radius: 18, x: 0, y: 10)
                Image(systemName: icon)
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(animateIn || reduceMotion ? 0 : -12))
            }
            .opacity(animateIn || reduceMotion ? 1 : 0)
            .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7), value: animateIn)

            VStack(spacing: 10) {
                Text(title)
                    .font(AppTheme.roundedTitle(28))
                    .foregroundStyle(AppTheme.ink)
                Text(subtitle)
                    .font(AppTheme.roundedBody(16, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 32)
            }
            .opacity(animateIn || reduceMotion ? 1 : 0)
            .offset(y: animateIn || reduceMotion ? 0 : 16)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.45).delay(0.15), value: animateIn)
        }
        .onAppear {
            animateIn = true
        }
    }
}

private struct PhotoToWorksheetHero: View {
    @State private var animateIn = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.paper.opacity(0.68), AppTheme.creamDeep.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 290, height: 238)
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .strokeBorder(.white.opacity(0.72), lineWidth: 1)
                )
                .shadow(color: AppTheme.ink.opacity(0.08), radius: 22, x: 0, y: 12)

            PhotoCard()
                .rotationEffect(.degrees(animateIn || reduceMotion ? -7 : -2))
                .offset(x: animateIn || reduceMotion ? -64 : -42, y: animateIn || reduceMotion ? -10 : 8)

            OnboardingWorksheetCard()
                .rotationEffect(.degrees(animateIn || reduceMotion ? 6 : 2))
                .offset(x: animateIn || reduceMotion ? 62 : 38, y: animateIn || reduceMotion ? 12 : 26)

            Circle()
                .fill(AppTheme.sun)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)
                )
                .shadow(color: AppTheme.sun.opacity(0.40), radius: 12, x: 0, y: 6)
                .scaleEffect(animateIn || reduceMotion ? 1 : 0.75)
        }
        .frame(height: 260)
        .opacity(animateIn || reduceMotion ? 1 : 0)
        .animation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.72), value: animateIn)
        .onAppear { animateIn = true }
        .accessibilityHidden(true)
    }
}

private struct PhotoCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [AppTheme.skySoft, AppTheme.mint, AppTheme.sunSoft],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 138, height: 176)
            .overlay(alignment: .topLeading) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .padding(14)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(.white.opacity(0.82))
                    .padding(16)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.72), lineWidth: 2)
            )
            .shadow(color: AppTheme.sky.opacity(0.18), radius: 14, x: 0, y: 8)
    }
}

private struct OnboardingWorksheetCard: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.white)
            .frame(width: 146, height: 196)
            .overlay(alignment: .top) {
                VStack(spacing: 10) {
                    Capsule()
                        .fill(AppTheme.coral.opacity(0.18))
                        .frame(width: 72, height: 10)
                    HStack(alignment: .bottom, spacing: 10) {
                        Text("A")
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundStyle(AppTheme.coral)
                        VStack(alignment: .leading, spacing: 6) {
                            worksheetLine(width: 42, color: AppTheme.skySoft)
                            worksheetLine(width: 34, color: AppTheme.sun)
                            worksheetLine(width: 48, color: AppTheme.mint)
                        }
                    }
                    VStack(spacing: 7) {
                        worksheetLine(width: 106, color: AppTheme.ink.opacity(0.12))
                        worksheetLine(width: 92, color: AppTheme.ink.opacity(0.10))
                        worksheetLine(width: 112, color: AppTheme.ink.opacity(0.10))
                    }
                    HStack(spacing: 7) {
                        ForEach(0..<3, id: \.self) { idx in
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(idx == 0 ? AppTheme.coral.opacity(0.75) : AppTheme.ink.opacity(0.10), lineWidth: 2)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                .padding(.top, 18)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppTheme.ink.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: AppTheme.ink.opacity(0.09), radius: 16, x: 0, y: 9)
    }

    private func worksheetLine(width: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: 6)
    }
}
