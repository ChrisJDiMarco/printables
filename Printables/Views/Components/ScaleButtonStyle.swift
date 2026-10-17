import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97
    var hapticFeel: HapticFeel? = .light
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? scale : 1)
            .brightness(configuration.isPressed ? -0.02 : 0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.55),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed, let feel = hapticFeel {
                    Haptics.shared.play(feel)
                }
            }
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scaled: ScaleButtonStyle { ScaleButtonStyle() }
    static func scaled(haptic: HapticFeel?) -> ScaleButtonStyle {
        ScaleButtonStyle(hapticFeel: haptic)
    }
}
