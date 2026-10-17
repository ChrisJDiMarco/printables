import UIKit

enum HapticFeel {
    case light
    case medium
    case soft
    case rigid
    case success
    case warning
    case error
    case selection
}

@MainActor
final class Haptics {
    static let shared = Haptics()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    var isEnabled: Bool = true

    private init() {
        prepareAll()
    }

    func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        notification.prepare()
        selectionGenerator.prepare()
    }

    func play(_ feel: HapticFeel) {
        guard isEnabled else { return }
        switch feel {
        case .light: lightImpact.impactOccurred()
        case .medium: mediumImpact.impactOccurred()
        case .soft: softImpact.impactOccurred()
        case .rigid: rigidImpact.impactOccurred()
        case .success: notification.notificationOccurred(.success)
        case .warning: notification.notificationOccurred(.warning)
        case .error: notification.notificationOccurred(.error)
        case .selection: selectionGenerator.selectionChanged()
        }
    }
}
