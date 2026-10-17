import SwiftUI
import Combine

struct Toast: Identifiable, Equatable {
    enum Tone: Equatable {
        case success
        case info
        case warning
        case error
    }

    let id = UUID()
    let title: String
    let message: String?
    let tone: Tone
    let systemImage: String

    static func success(_ title: String, message: String? = nil) -> Toast {
        Toast(title: title, message: message, tone: .success, systemImage: "checkmark.circle.fill")
    }

    static func info(_ title: String, message: String? = nil) -> Toast {
        Toast(title: title, message: message, tone: .info, systemImage: "info.circle.fill")
    }

    static func warning(_ title: String, message: String? = nil) -> Toast {
        Toast(title: title, message: message, tone: .warning, systemImage: "exclamationmark.triangle.fill")
    }

    static func error(_ title: String, message: String? = nil) -> Toast {
        Toast(title: title, message: message, tone: .error, systemImage: "xmark.octagon.fill")
    }
}

@MainActor
final class ToastCenter: ObservableObject {
    static let shared = ToastCenter()

    @Published var current: Toast?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ toast: Toast, duration: TimeInterval = 3.2) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            current = toast
        }
        switch toast.tone {
        case .success: Haptics.shared.play(.success)
        case .warning: Haptics.shared.play(.warning)
        case .error: Haptics.shared.play(.error)
        case .info: Haptics.shared.play(.soft)
        }
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                guard let self else { return }
                if self.current == toast {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        self.current = nil
                    }
                }
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            current = nil
        }
    }
}

struct ToastOverlay: ViewModifier {
    @ObservedObject private var center = ToastCenter.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = center.current {
                    ToastBanner(toast: toast)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { center.dismiss() }
                        .zIndex(999)
                }
            }
    }
}

extension View {
    func toastOverlay() -> some View { modifier(ToastOverlay()) }
}

private struct ToastBanner: View {
    let toast: Toast

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: toast.systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(AppTheme.roundedBody(14, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                if let message = toast.message {
                    Text(message)
                        .font(AppTheme.roundedBody(12, weight: .medium))
                        .foregroundStyle(AppTheme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(color: AppTheme.ink.opacity(0.12), radius: 18, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var accentColor: Color {
        switch toast.tone {
        case .success: return AppTheme.mint
        case .info: return AppTheme.sky
        case .warning: return AppTheme.sun
        case .error: return AppTheme.coral
        }
    }
}
