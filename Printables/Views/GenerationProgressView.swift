import SwiftUI

struct GenerationProgressView: View {
    @ObservedObject var generator: WorksheetGenerator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var pulse: Bool = false
    @State private var rotate: Double = 0
    @State private var stageIndex: Int = 0

    private let stageMessages: [(title: String, subtitle: String, icon: String, color: Color)] = [
        ("Looking closely", "Noticing colors, shapes, and details.", "eye.fill", AppTheme.sky),
        ("Picking activities", "Choosing what works best for this age.", "wand.and.stars", AppTheme.coral),
        ("Writing the lesson", "Crafting warm, playful words.", "pencil.and.scribble", AppTheme.lilac),
        ("Drawing the page", "Adding final touches.", "doc.text.fill", AppTheme.mint)
    ]

    var body: some View {
        ZStack {
            CreamBackground()
            VStack(spacing: 28) {
                Spacer()

                animatedMascot

                VStack(spacing: 12) {
                    Text(stageTitle)
                        .font(AppTheme.roundedTitle(26))
                        .foregroundStyle(AppTheme.ink)
                        .multilineTextAlignment(.center)
                        .id(stageTitle)
                        .transition(.opacity)

                    Text(stageSubtitle)
                        .font(AppTheme.roundedBody(15, weight: .medium))
                        .foregroundStyle(AppTheme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(2)
                        .id(stageSubtitle)
                        .transition(.opacity)
                }

                progressIndicator

                Spacer()

                if case .failed = generator.stage {
                    PrimaryButton("Try again", systemImage: "arrow.counterclockwise") {
                        dismiss()
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 16)
                } else if isWorking {
                    Button {
                        Haptics.shared.play(.warning)
                        generator.cancel()
                    } label: {
                        Text("Cancel")
                            .font(AppTheme.roundedBody(15, weight: .heavy))
                            .foregroundStyle(AppTheme.inkSoft)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(AppTheme.ink.opacity(0.08), lineWidth: 1))
                            .shadow(color: AppTheme.ink.opacity(0.04), radius: 6, x: 0, y: 2)
                    }
                    .buttonStyle(.scaled(haptic: nil))
                    .padding(.bottom, 32)
                    .accessibilityHint("Stop generating this worksheet")
                }
            }
        }
        .onAppear { startAnimations() }
        .onChange(of: stageIdentifier) { _, _ in
            Haptics.shared.play(.soft)
        }
        .onChange(of: isFinished) { _, isDone in
            if isDone {
                dismiss()
            }
        }
    }

    private var isWorking: Bool {
        switch generator.stage {
        case .analyzing, .writing, .rendering: return true
        default: return false
        }
    }

    private var isFinished: Bool {
        switch generator.stage {
        case .done, .failed, .cancelled: return true
        default: return false
        }
    }

    private var animatedMascot: some View {
        ZStack {
            ForEach(0..<3) { idx in
                Circle()
                    .stroke(stageColor.opacity(0.25 - Double(idx) * 0.06), lineWidth: 2)
                    .frame(width: 160 + CGFloat(idx) * 28, height: 160 + CGFloat(idx) * 28)
                    .scaleEffect(pulse ? 1.04 : 0.96)
                    .animation(
                        reduceMotion
                            ? nil
                            : .easeInOut(duration: 1.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(idx) * 0.2),
                        value: pulse
                    )
            }

            Mascot(
                mood: mascotMoodForStage,
                size: 132
            )
            .rotationEffect(.degrees(reduceMotion ? 0 : sin(rotate) * 4))
            .animation(reduceMotion ? nil : .easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: rotate)
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(stageMessages.indices, id: \.self) { idx in
                Capsule()
                    .fill(idx <= currentStageIndex ? stageColor : AppTheme.ink.opacity(0.10))
                    .frame(width: idx == currentStageIndex ? 28 : 10, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStageIndex)
            }
        }
    }

    private var stageIdentifier: String {
        switch generator.stage {
        case .idle: return "idle"
        case .analyzing: return "analyzing"
        case .writing: return "writing"
        case .rendering: return "rendering"
        case .done: return "done"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        }
    }

    private var currentStageIndex: Int {
        switch generator.stage {
        case .idle, .analyzing: return 0
        case .writing: return 1
        case .rendering: return 3
        case .done: return stageMessages.count - 1
        case .failed, .cancelled: return 0
        }
    }

    private var mascotMoodForStage: MascotMood {
        switch generator.stage {
        case .done: return .celebrating
        case .failed: return .thinking
        case .cancelled: return .sleeping
        case .idle: return .waving
        default: return .curious
        }
    }

    private var stageTitle: String {
        switch generator.stage {
        case .idle: return "Getting ready"
        case .analyzing: return stageMessages[0].title
        case .writing: return stageMessages[1].title
        case .rendering: return stageMessages[3].title
        case .done: return "All done!"
        case .failed: return "Hmm, something went wrong"
        case .cancelled: return "Stopped"
        }
    }

    private var stageSubtitle: String {
        switch generator.stage {
        case .idle: return "Warming up the crayons."
        case .analyzing: return stageMessages[0].subtitle
        case .writing: return stageMessages[1].subtitle
        case .rendering: return stageMessages[3].subtitle
        case .done: return "Tap to view and print."
        case .failed(let message): return message
        case .cancelled: return "You can try again whenever you're ready."
        }
    }

    private var stageColor: Color {
        switch generator.stage {
        case .idle, .analyzing: return AppTheme.sky
        case .writing: return AppTheme.coral
        case .rendering: return AppTheme.mint
        case .done: return AppTheme.sun
        case .failed: return AppTheme.coral
        case .cancelled: return AppTheme.lilac
        }
    }

    private func startAnimations() {
        pulse = true
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                rotate = .pi
            }
        }
    }
}
