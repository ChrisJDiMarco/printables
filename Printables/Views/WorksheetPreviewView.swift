import SwiftUI
import PDFKit
import UIKit
import Photos

struct WorksheetPreviewView: View {
    let initialWorksheet: Worksheet
    var celebrate: Bool = false
    @EnvironmentObject private var store: WorksheetStore
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var worksheet: Worksheet
    @State private var pdfData: Data?
    @State private var showShareSheet = false
    @State private var showDeleteConfirm = false
    @State private var showRenameSheet = false
    @State private var showRegenerateSheet = false
    @State private var isRegenerating = false
    @State private var regenerationError: String?
    @State private var confettiTrigger = 0
    @State private var headerScale: CGFloat = 1

    init(worksheet: Worksheet, celebrate: Bool = false) {
        self.initialWorksheet = worksheet
        self.celebrate = celebrate
        self._worksheet = State(initialValue: worksheet)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            CreamBackground(showDots: false)

            VStack(spacing: 0) {
                header

                if let data = pdfData {
                    PDFPreview(data: data)
                        .padding(.horizontal, 12)
                } else {
                    loadingPlaceholder
                }

                // Reserve space so PDF preview doesn't render under action bar + tab bar
                Color.clear.frame(height: PreviewLayout.actionBarHeight + PreviewLayout.tabBarReservedHeight)
            }

            actionBar
                .padding(.bottom, PreviewLayout.tabBarReservedHeight)

            if isRegenerating {
                regenerationOverlay
            }

            if celebrate && settings.confettiEnabled {
                ConfettiView(trigger: confettiTrigger)
                    .ignoresSafeArea()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 6) {
                    favoriteButton
                    menu
                }
            }
        }
        .onAppear {
            loadPDFData()
            if celebrate {
                confettiTrigger += 1
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = pdfData {
                ShareSheet(items: [pdfFileURL(data: data)])
            }
        }
        .sheet(isPresented: $showRenameSheet) {
            RenameSheet(worksheet: $worksheet) { updated in
                store.update(updated)
                regeneratePDF()
                ToastCenter.shared.show(.success("Title updated"))
            }
        }
        .alert("Delete this worksheet?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.delete(worksheet)
                Haptics.shared.play(.warning)
                ToastCenter.shared.show(.info("Worksheet deleted"))
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the worksheet and its photo.")
        }
        .alert("Couldn't regenerate", isPresented: Binding(
            get: { regenerationError != nil },
            set: { if !$0 { regenerationError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(regenerationError ?? "")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text(worksheet.content.title)
                .font(AppTheme.roundedTitle(22))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 8) {
                badge(worksheet.content.subjectLabel, color: AppTheme.coral)
                if let ageRaw = worksheet.ageRangeRaw, let age = AgeRange(rawValue: ageRaw) {
                    badge(age.label, color: AppTheme.sky)
                }
                if let name = worksheet.childName, !name.isEmpty {
                    badge("For \(name)", color: AppTheme.mint)
                }
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.roundedBody(11, weight: .heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            PrimaryButton("Share / Print", systemImage: "square.and.arrow.up", background: AppTheme.sky) {
                showShareSheet = true
            }
            Button {
                printPDF()
            } label: {
                Image(systemName: "printer.fill")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 56, height: 56)
                    .foregroundStyle(.white)
                    .background(AppTheme.coral)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
                    .shadow(color: AppTheme.coral.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.scaled(haptic: .medium))
            .accessibilityLabel("Print worksheet")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(AppTheme.ink.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: AppTheme.ink.opacity(0.10), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 18)
    }

    private var favoriteButton: some View {
        Button {
            Haptics.shared.play(worksheet.isFavorite ? .light : .success)
            worksheet.isFavorite.toggle()
            store.update(worksheet)
            ToastCenter.shared.show(.success(worksheet.isFavorite ? "Starred" : "Removed from favorites"))
        } label: {
            Image(systemName: worksheet.isFavorite ? "star.fill" : "star")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(worksheet.isFavorite ? AppTheme.sun : AppTheme.ink)
                .symbolEffect(.bounce, value: worksheet.isFavorite)
        }
        .accessibilityLabel(worksheet.isFavorite ? "Remove from favorites" : "Add to favorites")
    }

    private var menu: some View {
        Menu {
            Button {
                Haptics.shared.play(.light)
                showRenameSheet = true
            } label: {
                Label("Edit title", systemImage: "pencil")
            }
            Button {
                Haptics.shared.play(.medium)
                regenerateContent()
            } label: {
                Label("Regenerate", systemImage: "arrow.triangle.2.circlepath")
            }
            Button {
                savePDFToFiles()
            } label: {
                Label("Save PDF to Files", systemImage: "folder")
            }
            Divider()
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete worksheet", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AppTheme.ink)
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .tint(AppTheme.coral)
            Text("Loading worksheet…")
                .font(AppTheme.roundedBody(13, weight: .medium))
                .foregroundStyle(AppTheme.inkSoft)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var regenerationOverlay: some View {
        ZStack {
            AppTheme.ink.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 18) {
                Mascot(mood: .thinking, size: 100)
                Text("Designing a new version…")
                    .font(AppTheme.roundedBody(15, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(28)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: AppTheme.ink.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }

    private func loadPDFData() {
        if let filename = worksheet.pdfFilename,
           let data = ImageStore.shared.loadPDF(named: filename) {
            self.pdfData = data
            return
        }
        regeneratePDF()
    }

    private func regeneratePDF() {
        let renderer = PDFRenderer(paperSize: settings.paperSize)
        if let imageName = worksheet.worksheetImageFilename,
           let aiImage = ImageStore.shared.loadWorksheetImage(named: imageName) {
            let data = renderer.renderImagePage(image: aiImage, title: worksheet.content.title)
            self.pdfData = data
            if let filename = ImageStore.shared.savePDF(data, id: worksheet.id) {
                var updated = worksheet
                updated.pdfFilename = filename
                self.worksheet = updated
                store.update(updated)
            }
            return
        }
        let photo = worksheet.imageFilename.flatMap { ImageStore.shared.loadImage(named: $0) }
        let data = renderer.render(worksheet: worksheet, photo: photo)
        self.pdfData = data
        if let filename = ImageStore.shared.savePDF(data, id: worksheet.id) {
            var updated = worksheet
            updated.pdfFilename = filename
            self.worksheet = updated
            store.update(updated)
        }
    }

    private func regenerateContent() {
        guard settings.hasOpenAIKey else {
            regenerationError = "Add your OpenAI API key in Settings first."
            return
        }
        guard let filename = worksheet.imageFilename,
              let image = ImageStore.shared.loadImage(named: filename) else {
            regenerationError = "The original photo is missing."
            return
        }

        let profile = ChildProfile(
            id: worksheet.profileID ?? UUID(),
            name: worksheet.childName ?? "",
            ageRange: worksheet.ageRangeRaw.flatMap { AgeRange(rawValue: $0) } ?? settings.activeProfile.ageRange,
            color: worksheet.profileColorRaw.flatMap { ProfileColor(rawValue: $0) } ?? settings.activeProfile.color
        )
        let style = worksheet.style ?? settings.defaultStyle

        isRegenerating = true
        Task {
            do {
                let brief = try await OpenAIImageService.shared.brief(
                    photo: image,
                    teachingGoal: worksheet.teachingGoal,
                    profile: profile,
                    apiKey: settings.openAIKey,
                    visionModel: settings.visionModel
                )

                let aiImage = try await OpenAIImageService.shared.generateWorksheetImage(
                    brief: brief,
                    style: style,
                    profile: profile,
                    apiKey: settings.openAIKey,
                    imageModel: settings.imageModel,
                    quality: settings.imageQuality
                )

                await MainActor.run {
                    var updated = worksheet
                    updated.content = .from(brief: brief)
                    if let filename = ImageStore.shared.saveWorksheetImage(aiImage, id: updated.id) {
                        updated.worksheetImageFilename = filename
                    }
                    worksheet = updated
                    store.update(updated)
                    regeneratePDF()
                    isRegenerating = false
                    Haptics.shared.play(.success)
                    ToastCenter.shared.show(.success("Fresh worksheet ready"))
                }
            } catch let error as OpenAIImageError {
                await MainActor.run {
                    isRegenerating = false
                    regenerationError = error.errorDescription
                }
            } catch {
                await MainActor.run {
                    isRegenerating = false
                    regenerationError = error.localizedDescription
                }
            }
        }
    }

    private func pdfFileURL(data: Data) -> URL {
        let cleanTitle = worksheet.content.title
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "_")
        let filename = "\(cleanTitle.isEmpty ? "worksheet" : cleanTitle).pdf"
        let tempDir = FileManager.default.temporaryDirectory
        let url = tempDir.appendingPathComponent(filename)
        try? data.write(to: url, options: .atomic)
        return url
    }

    private func printPDF() {
        guard let data = pdfData else { return }
        let printController = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = worksheet.content.title
        printController.printInfo = info
        printController.printingItem = data
        printController.present(animated: true, completionHandler: nil)
    }

    private func savePDFToFiles() {
        guard let data = pdfData else { return }
        let url = pdfFileURL(data: data)
        let controller = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        controller.shouldShowFileExtensions = true
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        root.present(controller, animated: true)
        ToastCenter.shared.show(.info("Choose where to save"))
    }
}

private struct RenameSheet: View {
    @Binding var worksheet: Worksheet
    let onSave: (Worksheet) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var draft: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                CreamBackground()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Edit title")
                        .font(AppTheme.roundedTitle(22))
                        .foregroundStyle(AppTheme.ink)
                    TextField("Worksheet title", text: $draft)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .font(AppTheme.roundedBody(15, weight: .medium))
                        .padding(14)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(AppTheme.ink.opacity(0.08), lineWidth: 1)
                        )
                    Spacer()
                    PrimaryButton("Save") {
                        var updated = worksheet
                        updated.content = WorksheetContent(
                            title: draft.trimmingCharacters(in: .whitespacesAndNewlines),
                            subjectLabel: updated.content.subjectLabel,
                            intro: updated.content.intro,
                            funFact: updated.content.funFact,
                            learningGoals: updated.content.learningGoals,
                            traceWord: updated.content.traceWord,
                            countingItem: updated.content.countingItem,
                            countingTarget: updated.content.countingTarget,
                            coloringPrompt: updated.content.coloringPrompt,
                            drawingPrompt: updated.content.drawingPrompt,
                            questions: updated.content.questions,
                            vocabulary: updated.content.vocabulary,
                            parentTip: updated.content.parentTip
                        )
                        worksheet = updated
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    SecondaryButton("Cancel") { dismiss() }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { draft = worksheet.content.title }
        }
    }
}

private enum PreviewLayout {
    /// Visible height of the action bar (Share/Print buttons) including padding
    static let actionBarHeight: CGFloat = 78
    /// Space reserved above the screen bottom edge for the floating tab bar
    static let tabBarReservedHeight: CGFloat = 96
}
