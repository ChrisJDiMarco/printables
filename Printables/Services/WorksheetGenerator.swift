import Foundation
import UIKit
import Combine

@MainActor
final class WorksheetGenerator: ObservableObject {
    enum Stage: Equatable {
        case idle
        case analyzing
        case writing
        case rendering
        case done(Worksheet)
        case failed(String)
        case cancelled
    }

    @Published var stage: Stage = .idle
    private var generationTask: Task<Void, Never>?

    private let openAIService: OpenAIServiceProviding
    private let imageStore: ImageStore
    private let store: WorksheetStore
    private let pdfRenderer: PDFRenderer

    init(
        openAIService: OpenAIServiceProviding = OpenAIImageService.shared,
        imageStore: ImageStore = .shared,
        store: WorksheetStore,
        paperSize: PaperSize
    ) {
        self.openAIService = openAIService
        self.imageStore = imageStore
        self.store = store
        self.pdfRenderer = PDFRenderer(paperSize: paperSize)
    }

    func cancel() {
        generationTask?.cancel()
        generationTask = nil
        stage = .cancelled
    }

    func generate(
        image: UIImage,
        teachingGoal: String,
        profile: ChildProfile,
        style: WorksheetStyle,
        openAIKey: String,
        visionModel: String,
        imageModel: String,
        quality: ImageQuality
    ) {
        generationTask?.cancel()
        stage = .analyzing
        generationTask = Task { [weak self] in
            guard let self else { return }
            do {
                if Task.isCancelled { return }

                let brief = try await self.openAIService.brief(
                    photo: image,
                    teachingGoal: teachingGoal,
                    profile: profile,
                    apiKey: openAIKey,
                    visionModel: visionModel
                )
                if Task.isCancelled { return }

                await MainActor.run { self.stage = .writing }
                if Task.isCancelled { return }

                await MainActor.run { self.stage = .rendering }

                let generatedImage = try await self.openAIService.generateWorksheetImage(
                    brief: brief,
                    style: style,
                    profile: profile,
                    apiKey: openAIKey,
                    imageModel: imageModel,
                    quality: quality
                )
                if Task.isCancelled { return }

                let worksheetID = UUID()
                let photoFilename = self.imageStore.saveImage(image, id: worksheetID)
                let worksheetImageFilename = self.imageStore.saveWorksheetImage(generatedImage, id: worksheetID)
                let pdfData = self.pdfRenderer.renderImagePage(image: generatedImage, title: brief.title)
                let pdfFilename = self.imageStore.savePDF(pdfData, id: worksheetID)

                let worksheet = Worksheet(
                    id: worksheetID,
                    subject: brief.subjectLabel,
                    teachingGoal: teachingGoal,
                    content: .from(brief: brief),
                    imageFilename: photoFilename,
                    pdfFilename: pdfFilename,
                    worksheetImageFilename: worksheetImageFilename,
                    styleRaw: style.rawValue,
                    childName: profile.hasName ? profile.name : nil,
                    ageRangeRaw: profile.ageRange.rawValue,
                    profileID: profile.id,
                    profileColorRaw: profile.colorRaw,
                    isFavorite: false
                )

                await MainActor.run {
                    self.store.add(worksheet)
                    self.stage = .done(worksheet)
                }
            } catch let error as OpenAIImageError {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.stage = .failed(error.errorDescription ?? "Unknown error")
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.stage = .failed(error.localizedDescription)
                }
            }
        }
    }
}
