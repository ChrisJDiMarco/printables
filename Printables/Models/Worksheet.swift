import Foundation
import UIKit

struct Worksheet: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let createdAt: Date
    let subject: String
    let teachingGoal: String
    var content: WorksheetContent
    var imageFilename: String?
    var pdfFilename: String?
    var worksheetImageFilename: String?
    var styleRaw: String?
    var childName: String?
    var ageRangeRaw: String?
    var profileID: UUID?
    var profileColorRaw: String?
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        subject: String,
        teachingGoal: String,
        content: WorksheetContent,
        imageFilename: String? = nil,
        pdfFilename: String? = nil,
        worksheetImageFilename: String? = nil,
        styleRaw: String? = nil,
        childName: String? = nil,
        ageRangeRaw: String? = nil,
        profileID: UUID? = nil,
        profileColorRaw: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.subject = subject
        self.teachingGoal = teachingGoal
        self.content = content
        self.imageFilename = imageFilename
        self.pdfFilename = pdfFilename
        self.worksheetImageFilename = worksheetImageFilename
        self.styleRaw = styleRaw
        self.childName = childName
        self.ageRangeRaw = ageRangeRaw
        self.profileID = profileID
        self.profileColorRaw = profileColorRaw
        self.isFavorite = isFavorite
    }

    var style: WorksheetStyle? {
        styleRaw.flatMap { WorksheetStyle(rawValue: $0) }
    }
}

extension WorksheetContent {
    static func from(brief: WorksheetBrief) -> WorksheetContent {
        WorksheetContent(
            title: brief.title,
            subjectLabel: brief.subjectLabel,
            intro: brief.intro,
            funFact: brief.funFact,
            learningGoals: brief.learningGoals,
            traceWord: brief.traceWord,
            countingItem: brief.countingItem,
            countingTarget: brief.countingTarget,
            coloringPrompt: brief.coloringPrompt,
            drawingPrompt: brief.drawingPrompt,
            questions: brief.questions,
            vocabulary: brief.vocabulary,
            parentTip: brief.parentTip
        )
    }
}

struct WorksheetContent: Codable, Equatable, Hashable {
    let title: String
    let subjectLabel: String
    let intro: String
    let funFact: String
    let learningGoals: [String]
    let traceWord: String
    let countingItem: String
    let countingTarget: Int
    let coloringPrompt: String
    let drawingPrompt: String
    let questions: [String]
    let vocabulary: [VocabularyEntry]
    let parentTip: String

    static let empty = WorksheetContent(
        title: "Let's Learn!",
        subjectLabel: "Subject",
        intro: "A fun page to learn together.",
        funFact: "Every day is a chance to learn something new.",
        learningGoals: ["Looking", "Listening", "Learning"],
        traceWord: "LEARN",
        countingItem: "stars",
        countingTarget: 5,
        coloringPrompt: "Color the picture using your favorite colors.",
        drawingPrompt: "Draw your own version below.",
        questions: ["What do you see?", "How does it make you feel?"],
        vocabulary: [],
        parentTip: "Ask open-ended questions while your child works."
    )
}

struct VocabularyEntry: Codable, Equatable, Hashable, Identifiable {
    var id: String { word }
    let word: String
    let definition: String
}
