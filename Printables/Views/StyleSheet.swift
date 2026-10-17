import SwiftUI

struct StyleSheet: View {
    @Binding var selection: WorksheetStyle
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                CreamBackground()
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(WorksheetStyle.allCases) { style in
                            StyleGridCard(
                                style: style,
                                isSelected: style == selection
                            ) {
                                Haptics.shared.play(.selection)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                                    selection = style
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Pick a style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.roundedBody(15, weight: .heavy))
                }
            }
        }
    }
}

private struct StyleGridCard: View {
    let style: WorksheetStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: style.swatchColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .aspectRatio(1.2, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                        )

                    VStack(spacing: 8) {
                        Text(style.emoji)
                            .font(.system(size: 38))
                            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                        Text(style.displayName.uppercased())
                            .font(AppTheme.roundedBody(11, weight: .heavy))
                            .kerning(0.6)
                            .foregroundStyle(style.isDarkBackground ? .white : AppTheme.ink)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(style.displayName)
                            .font(AppTheme.roundedBody(15, weight: .heavy))
                            .foregroundStyle(AppTheme.ink)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.coral)
                        }
                    }
                    Text(style.tagline)
                        .font(AppTheme.roundedBody(12, weight: .medium))
                        .foregroundStyle(AppTheme.inkSoft)
                        .lineLimit(1)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppTheme.coral : AppTheme.ink.opacity(0.04),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: AppTheme.ink.opacity(isSelected ? 0.10 : 0.05), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.scaled(haptic: nil))
        .accessibilityLabel("\(style.displayName) style. \(style.tagline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct StyleChip: View {
    let style: WorksheetStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: style.swatchColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                        )
                    Text(style.emoji)
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("STYLE")
                        .font(AppTheme.roundedBody(10, weight: .heavy))
                        .foregroundStyle(AppTheme.inkSoft)
                        .kerning(1.0)
                    HStack(spacing: 4) {
                        Text(style.displayName)
                            .font(AppTheme.roundedBody(14, weight: .heavy))
                            .foregroundStyle(AppTheme.ink)
                        Text("·")
                            .font(AppTheme.roundedBody(13, weight: .heavy))
                            .foregroundStyle(AppTheme.inkSoft.opacity(0.6))
                        Text(style.tagline)
                            .font(AppTheme.roundedBody(13, weight: .medium))
                            .foregroundStyle(AppTheme.inkSoft)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.inkSoft.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppTheme.creamDeep.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(AppTheme.ink.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.scaled(haptic: .light))
        .accessibilityLabel("Style: \(style.displayName). Tap to change.")
    }
}
