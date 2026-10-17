import SwiftUI

struct StylePicker: View {
    @Binding var selection: WorksheetStyle

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(WorksheetStyle.allCases) { style in
                    StyleTile(style: style, isSelected: selection == style) {
                        Haptics.shared.play(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                            selection = style
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
    }
}

private struct StyleTile: View {
    let style: WorksheetStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: style.swatchColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 78, height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(.white.opacity(0.5), lineWidth: 1)
                        )
                    Text(style.emoji)
                        .font(.system(size: 24))
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                }

                VStack(spacing: 1) {
                    Text(style.displayName)
                        .font(AppTheme.roundedBody(12, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)
                    Text(style.tagline)
                        .font(AppTheme.roundedBody(10, weight: .medium))
                        .foregroundStyle(AppTheme.inkSoft)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppTheme.coral : AppTheme.ink.opacity(0.06),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: AppTheme.ink.opacity(isSelected ? 0.10 : 0.04), radius: 8, x: 0, y: 4)
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.coral)
                        .background(Circle().fill(.white))
                        .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.scaled(haptic: nil))
        .accessibilityLabel("\(style.displayName) style. \(style.tagline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    StatefulPreviewWrapper(WorksheetStyle.pastel) { binding in
        StylePicker(selection: binding)
            .frame(maxWidth: .infinity, maxHeight: 130)
            .background(AppTheme.cream)
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    let content: (Binding<Value>) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        self._value = State(initialValue: value)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
