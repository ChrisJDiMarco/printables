import Foundation
import UIKit

enum OpenAIImageError: LocalizedError {
    case missingAPIKey
    case invalidImage
    case invalidResponse
    case network(String)
    case decoding(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add your OpenAI API key in Settings to generate worksheets."
        case .invalidImage:
            return "Couldn't read that photo. Try another one."
        case .invalidResponse:
            return "Couldn't read the AI's response."
        case .network(let msg):
            return "Network problem: \(msg)"
        case .decoding(let msg):
            return "Decoding error: \(msg)"
        case .cancelled:
            return "Cancelled."
        }
    }
}

struct WorksheetBrief: Codable, Equatable {
    let title: String
    let subjectLabel: String
    let subjectDescription: String
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
    let activities: [WorksheetActivity]
    let layoutRaw: String
    let designNotes: String

    var layout: WorksheetLayout {
        WorksheetLayout(rawValue: layoutRaw) ?? .classicGrid
    }
}

protocol OpenAIServiceProviding {
    func brief(
        photo: UIImage,
        teachingGoal: String,
        profile: ChildProfile,
        apiKey: String,
        visionModel: String
    ) async throws -> WorksheetBrief

    func generateWorksheetImage(
        brief: WorksheetBrief,
        style: WorksheetStyle,
        profile: ChildProfile,
        apiKey: String,
        imageModel: String,
        quality: ImageQuality
    ) async throws -> UIImage
}

enum ImageQuality: String, CaseIterable, Identifiable {
    case low
    case medium
    case high

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .low: return "Fast"
        case .medium: return "Balanced"
        case .high: return "Highest"
        }
    }

    var apiValue: String { rawValue }
}

final class OpenAIImageService: OpenAIServiceProviding {
    static let shared = OpenAIImageService()

    private let chatEndpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let imageEndpoint = URL(string: "https://api.openai.com/v1/images/generations")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Step 1: Vision brief

    func brief(
        photo: UIImage,
        teachingGoal: String,
        profile: ChildProfile,
        apiKey: String,
        visionModel: String = "gpt-4o-mini"
    ) async throws -> WorksheetBrief {
        guard !apiKey.isEmpty else { throw OpenAIImageError.missingAPIKey }

        let resized = photo.downsized(maxDimension: 1024)
        guard let jpeg = resized.jpegData(compressionQuality: 0.85) else {
            throw OpenAIImageError.invalidImage
        }
        let base64 = jpeg.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64)"

        let prompt = buildBriefPrompt(teachingGoal: teachingGoal, profile: profile)

        let payload: [String: Any] = [
            "model": visionModel,
            "max_tokens": 1500,
            "response_format": ["type": "json_object"],
            "messages": [
                [
                    "role": "system",
                    "content": "You are a children's learning content designer. Respond ONLY with strict, valid JSON. No prose, no commentary, no markdown."
                ],
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": dataURL]]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: chatEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OpenAIImageError.network(error.localizedDescription)
        }

        try check(response: response, data: data)
        return try decodeBrief(from: data)
    }

    // MARK: - Step 2: Image generation

    func generateWorksheetImage(
        brief: WorksheetBrief,
        style: WorksheetStyle,
        profile: ChildProfile,
        apiKey: String,
        imageModel: String = "gpt-image-1",
        quality: ImageQuality = .high
    ) async throws -> UIImage {
        guard !apiKey.isEmpty else { throw OpenAIImageError.missingAPIKey }

        let prompt = buildImagePrompt(brief: brief, style: style, profile: profile)

        let payload: [String: Any] = [
            "model": imageModel,
            "prompt": prompt,
            "size": "1024x1536",
            "quality": quality.apiValue,
            "output_format": "png",
            "n": 1
        ]

        var request = URLRequest(url: imageEndpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw OpenAIImageError.network(error.localizedDescription)
        }

        try check(response: response, data: data)
        return try decodeImage(from: data)
    }

    // MARK: - Prompts

    private func buildBriefPrompt(teachingGoal: String, profile: ChildProfile) -> String {
        let focus: String
        let goal = teachingGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        if goal.isEmpty {
            focus = "Pick the most interesting age-appropriate angle you can teach from the photo."
        } else {
            focus = "The parent wants the worksheet to focus on: \"\(goal)\""
        }

        let childNote = profile.hasName
            ? "The child's name is \(profile.greetingName). Address them by name in intro and parent_tip."
            : "Do not invent a specific child name."

        let activityCatalog = ActivityKind.allCases.map { kind in
            "  - \"\(kind.rawValue)\" — \(kind.description)"
        }.joined(separator: "\n")

        let layoutCatalog = WorksheetLayout.allCases.map { layout in
            "  - \"\(layout.rawValue)\" — \(layout.promptHint)"
        }.joined(separator: "\n")

        return """
        Look carefully at the photo. Identify the main subject (object, animal, person, scene, or concept).

        \(focus)

        \(childNote)

        Design a 1-page printable worksheet for a child \(profile.ageRange.promptDescriptor). Warm, joyful, simple language.

        BESPOKE DESIGN: Every worksheet must feel custom-made for THIS specific subject and age. Do NOT use the same activity slots every time. Pick the activities and layout that ACTUALLY fit the subject:
        - A clock photo → time-telling, sequence-of-day, hands-of-the-clock
        - A leaf → label parts, life cycle, observe-and-write
        - A fire truck → label parts, path-to-safety, fact sheet, count windows
        - A pet → habitat, life cycle, opposites (loud/quiet), feelings
        - A food item → food groups, sort by category, recipe steps, healthy choices
        - A toy → describe, draw your own, feelings, sequence of play
        - A book/letter → trace word, fill-blank, alphabet find, rhyme

        ACTIVITY CATALOGUE — pick 3 to 5 that are genuinely the best fit for THIS subject + age:
        \(activityCatalog)

        LAYOUT CATALOGUE — pick the one that suits the subject best:
        \(layoutCatalog)

        Return ONLY valid JSON, no markdown, no commentary. Schema:
        {
          "title": "Short playful title, max 6 words, specific to this subject",
          "subject_label": "1-2 words naming the subject (e.g. 'Apple', 'Fire Truck', 'Maple Leaf')",
          "subject_description": "2-3 sentences vividly describing the subject's shape, color, texture, distinguishing features — the image AI will use this to redraw it",
          "intro": "1-2 sentence warm intro spoken directly to the child",
          "fun_fact": "One delightful, true, age-appropriate fact specific to this subject",
          "learning_goals": ["3 to 4 short skill tags relevant to this subject and age"],
          "trace_word": "UPPERCASE word the child traces, 3-7 letters",
          "counting_item": "Plural noun the child counts",
          "counting_target": 5,
          "coloring_prompt": "One sentence telling the child what to color",
          "drawing_prompt": "One sentence telling the child what to draw",
          "questions": ["2-3 open-ended discussion questions specific to this subject"],
          "vocabulary": [{"word": "lowercase", "definition": "Kid-friendly definition under 12 words"}],
          "parent_tip": "One sentence guiding the parent",
          "design_notes": "1-2 sentences describing what makes this worksheet bespoke for THIS subject (which 3-5 activities you picked and why)",
          "layout_raw": "exact value from layout catalogue — one of: classicGrid, heroScene, storyboard, explorerSpread, magazineSpread",
          "activities": [
            {
              "kind": "exact value from activity catalogue — must match one of the listed kinds",
              "title": "Short display title (e.g. 'Trace the word', 'Label the parts')",
              "instruction": "One short sentence telling the child what to do",
              "payload": {
                "key": "value pairs with kind-specific details"
              }
            }
          ]
        }

        Payload keys for each kind:
        - traceWord: { "word": "UPPERCASE" }
        - countObjects: { "item": "plural noun", "target": "3-10 as string" }
        - sortGroups: { "categories": "comma-separated category names", "items": "comma-separated items to sort" }
        - matchPairs: { "left": "comma-separated", "right": "comma-separated matching" }
        - colorOutline: { "subject": "what to color" }
        - colorByNumber: { "regions": "comma-separated label hints", "key": "1=red, 2=blue, 3=yellow, 4=green" }
        - drawBlank: { "prompt": "what to draw" }
        - drawSequence: { "first_frames": "what's already drawn", "completion": "what to add" }
        - connectDots: { "subject": "what shape the dots form", "count": "10-20 as string" }
        - mazePath: { "start": "what's at the start", "end": "what's at the end" }
        - findHidden: { "scene": "scene description", "items": "comma-separated items to find" }
        - wordBank: { "words": "word1: def1 | word2: def2 | word3: def3" }
        - discussion: { "questions": "comma-separated questions" }
        - labelParts: { "parts": "comma-separated part names" }
        - lifeCycle: { "stages": "comma-separated 4 stage names" }
        - habitatMap: { "environment": "habitat name and 1-line description" }
        - compareSize: { "items": "3-4 comma-separated, smallest first" }
        - sameDifferent: { "scene": "scene description", "differences": "comma-separated 4-5 differences" }
        - fillBlank: { "word": "FULL_WORD", "missing": "letter to omit" }
        - opposites: { "pairs": "hot/cold, day/night, big/small" }
        - timeOfDay: { "scenes": "morning, noon, evening, night" }
        - feelings: { "emotions": "comma-separated emotions to identify" }
        - pathToSafety: { "scenario": "fire / crossing / etc", "destination": "exit" }
        - foodGroups: { "groups": "Fruits, Vegetables, Grains, Protein", "items": "comma-separated foods" }
        - sequenceSteps: { "steps": "comma-separated steps in correct order" }
        - observe: { "prompt": "what to observe" }
        - factSheet: { "facts": "fact1 | fact2 | fact3 | fact4" }
        - traceShape: { "shape": "shape name" }

        Constraints:
        - counting_target must be 3 to 10
        - vocabulary should have 2 to 4 entries
        - trace_word must be uppercase A-Z only
        - activities array must have 3 to 5 entries
        - layout_raw must be one of the listed layouts
        - All activity kinds must match the catalogue exactly
        - No emoji, no URLs, no markdown
        """
    }

    private func buildImagePrompt(
        brief: WorksheetBrief,
        style: WorksheetStyle,
        profile: ChildProfile
    ) -> String {
        let learnerLine = profile.hasName
            ? "MADE FOR \(profile.greetingName.uppercased())"
            : "PRINTABLES FOR LITTLE LEARNERS"

        let goals = brief.learningGoals.prefix(4).map { "\"\($0)\"" }.joined(separator: ", ")

        let activities = brief.activities.isEmpty
            ? fallbackActivities(from: brief)
            : brief.activities

        let activityBlock = activities.enumerated().map { idx, activity in
            renderActivityForPrompt(activity, index: idx + 1, brief: brief)
        }.joined(separator: "\n\n")

        return """
        Create a single high-resolution PNG image of one printed worksheet page, US Letter portrait orientation. The image will be printed and given to a child — design it to look like a professionally-published learning page custom-made for this specific subject.

        SUBJECT: \(brief.subjectLabel)
        VISUAL DESCRIPTION OF THE SUBJECT: \(brief.subjectDescription)
        AUDIENCE: \(profile.ageRange.promptDescriptor)
        TONE: warm, joyful, encouraging, calm

        \(style.promptDescription)

        \(brief.layout.promptHint)

        BESPOKE INTENT: Every section of this worksheet should feel specifically chosen for THIS subject (not a generic template). The activities below were hand-picked by an editor to teach about this exact subject at this age level. Render each one carefully.

        OVERALL PAGE STRUCTURE:

        1. HEADER STRIP (top ~10% of page):
        - Centered small rounded pill with text: "\(learnerLine)"
        - Below it, large playful TITLE in heavy rounded type: "\(brief.title)"
        - Title centered

        2. HERO CARD (~20% height):
        - Wide rounded card
        - Charming illustrated rendering of the subject on one side
        - Other side: tiny uppercase label "TODAY WE LEARN ABOUT", big subject name "\(brief.subjectLabel)", the warm intro: "\(brief.intro)", and a row of small colorful skill chip-pills: \(goals)

        3. ACTIVITY SECTION (~55% of page) — render these activities in clear visual order. Use the layout direction above to decide how to arrange them on the page. Each activity sits in its own rounded card with a clear title.

        \(activityBlock)

        4. FOOTER BAND (~8% height):
        - Light card spanning full width
        - Small uppercase label "DID YOU KNOW?" then the sentence: "\(brief.funFact)"
        - Tiny italic line: "Grown-up tip: \(brief.parentTip)"
        - At very bottom center, tiny text: "Made for little curious minds"

        DESIGN RULES:
        - All rounded corners (radius 22-28pt)
        - 36pt margin on all sides
        - Lots of breathing room between sections, no crowding
        - Subtle soft drop shadows on cards
        - Decorative dot or pattern accents in corners (subtle, not overwhelming)
        - All text must be perfectly legible, spelled correctly, and grammatically clean
        - No emoji, no URLs, no watermarks, no logos other than the header pill
        - Output: one image, US Letter portrait aspect, high quality, print-ready

        FINAL REMINDER: \(style.tagline). Every visual choice should reinforce the style. The activities should look like they belong together — same illustration language, same typography, cohesive palette.
        """
    }

    private func renderActivityForPrompt(_ activity: WorksheetActivity, index: Int, brief: WorksheetBrief) -> String {
        let baseHint: String
        if let kind = ActivityKind(rawValue: activity.kind) {
            baseHint = kind.imagePromptInstruction
        } else {
            baseHint = activity.instruction
        }

        let payloadDetail = activity.payload
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \($0.value)" }
            .joined(separator: " · ")

        return """
        Activity \(index) — "\(activity.title)":
        - Instruction shown to the child: "\(activity.instruction)"
        - Visual rendering: \(baseHint)\(payloadDetail.isEmpty ? "" : "\n        - Specifics: \(payloadDetail)")
        """
    }

    /// Used when the brief AI didn't return an activities array — fall back to the legacy 4-activity template.
    private func fallbackActivities(from brief: WorksheetBrief) -> [WorksheetActivity] {
        [
            WorksheetActivity(
                kind: ActivityKind.traceWord.rawValue,
                title: "Trace the word",
                instruction: "Trace each letter with your finger or a pencil.",
                payload: ["word": brief.traceWord]
            ),
            WorksheetActivity(
                kind: ActivityKind.countObjects.rawValue,
                title: "Count and circle",
                instruction: "Count the \(brief.countingItem) and circle \(brief.countingTarget).",
                payload: ["item": brief.countingItem, "target": String(brief.countingTarget)]
            ),
            WorksheetActivity(
                kind: ActivityKind.colorOutline.rawValue,
                title: "Color it in",
                instruction: brief.coloringPrompt,
                payload: ["subject": brief.subjectLabel]
            ),
            WorksheetActivity(
                kind: ActivityKind.drawBlank.rawValue,
                title: "Draw your own",
                instruction: brief.drawingPrompt,
                payload: ["prompt": brief.drawingPrompt]
            ),
            WorksheetActivity(
                kind: ActivityKind.discussion.rawValue,
                title: "Let's chat",
                instruction: "Talk about these questions together.",
                payload: ["questions": brief.questions.joined(separator: ", ")]
            )
        ]
    }

    // MARK: - Decoding

    private func check(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIImageError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIImageError.network("HTTP \(http.statusCode): \(body.prefix(220))")
        }
    }

    private func decodeBrief(from data: Data) throws -> WorksheetBrief {
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable {
                    let content: String
                }
                let message: Message
            }
            let choices: [Choice]
        }

        let envelope: ChatResponse
        do {
            envelope = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw OpenAIImageError.decoding("response envelope")
        }

        guard let content = envelope.choices.first?.message.content,
              let jsonString = Self.extractJSONObject(from: content),
              let jsonData = jsonString.data(using: .utf8) else {
            throw OpenAIImageError.decoding("could not find JSON in response")
        }

        struct Payload: Decodable {
            let title: String
            let subject_label: String
            let subject_description: String
            let intro: String
            let fun_fact: String
            let learning_goals: [String]
            let trace_word: String
            let counting_item: String
            let counting_target: Int
            let coloring_prompt: String
            let drawing_prompt: String
            let questions: [String]
            let vocabulary: [VocabPayload]
            let parent_tip: String
            let layout_raw: String?
            let design_notes: String?
            let activities: [ActivityPayload]?

            struct VocabPayload: Decodable {
                let word: String
                let definition: String
            }

            struct ActivityPayload: Decodable {
                let kind: String
                let title: String
                let instruction: String
                let payload: [String: String]?
            }
        }

        let payload: Payload
        do {
            payload = try JSONDecoder().decode(Payload.self, from: jsonData)
        } catch {
            throw OpenAIImageError.decoding("schema mismatch — \(error.localizedDescription)")
        }

        let traceWord = payload.trace_word.uppercased().filter { $0.isLetter }
        let safeTrace = traceWord.isEmpty
            ? payload.subject_label.uppercased().filter { $0.isLetter }
            : traceWord
        let target = max(3, min(10, payload.counting_target))

        // Sanitize the activities — keep only known kinds, cap at 5
        let knownKinds = Set(ActivityKind.allCases.map { $0.rawValue })
        let activities = (payload.activities ?? [])
            .filter { knownKinds.contains($0.kind) }
            .prefix(5)
            .map {
                WorksheetActivity(
                    kind: $0.kind,
                    title: $0.title.trimmed(),
                    instruction: $0.instruction.trimmed(),
                    payload: $0.payload ?? [:]
                )
            }

        let layoutRaw = (payload.layout_raw.flatMap { WorksheetLayout(rawValue: $0) } ?? .classicGrid).rawValue

        return WorksheetBrief(
            title: payload.title.trimmed(),
            subjectLabel: payload.subject_label.trimmed(),
            subjectDescription: payload.subject_description.trimmed(),
            intro: payload.intro.trimmed(),
            funFact: payload.fun_fact.trimmed(),
            learningGoals: payload.learning_goals.map { $0.trimmed() }.filter { !$0.isEmpty },
            traceWord: String(safeTrace.prefix(8)),
            countingItem: payload.counting_item.trimmed(),
            countingTarget: target,
            coloringPrompt: payload.coloring_prompt.trimmed(),
            drawingPrompt: payload.drawing_prompt.trimmed(),
            questions: payload.questions.map { $0.trimmed() }.filter { !$0.isEmpty },
            vocabulary: payload.vocabulary.map { VocabularyEntry(word: $0.word.trimmed(), definition: $0.definition.trimmed()) },
            parentTip: payload.parent_tip.trimmed(),
            activities: Array(activities),
            layoutRaw: layoutRaw,
            designNotes: (payload.design_notes ?? "").trimmed()
        )
    }

    private func decodeImage(from data: Data) throws -> UIImage {
        struct ImageResponse: Decodable {
            struct Item: Decodable {
                let b64_json: String?
                let url: String?
            }
            let data: [Item]
        }

        let envelope: ImageResponse
        do {
            envelope = try JSONDecoder().decode(ImageResponse.self, from: data)
        } catch {
            throw OpenAIImageError.decoding("image envelope")
        }

        guard let first = envelope.data.first else {
            throw OpenAIImageError.decoding("no image returned")
        }

        if let b64 = first.b64_json,
           let imageData = Data(base64Encoded: b64),
           let image = UIImage(data: imageData) {
            return image
        }

        if let urlString = first.url, let url = URL(string: urlString) {
            let imageData = try Data(contentsOf: url)
            if let image = UIImage(data: imageData) {
                return image
            }
        }

        throw OpenAIImageError.decoding("image data unreadable")
    }

    static func extractJSONObject(from text: String) -> String? {
        guard let first = text.firstIndex(of: "{") else { return nil }
        var depth = 0
        var endIndex: String.Index?
        var inString = false
        var escape = false

        for idx in text[first...].indices {
            let ch = text[idx]
            if escape { escape = false; continue }
            if ch == "\\" { escape = true; continue }
            if ch == "\"" { inString.toggle(); continue }
            if inString { continue }
            if ch == "{" { depth += 1 }
            if ch == "}" {
                depth -= 1
                if depth == 0 {
                    endIndex = idx
                    break
                }
            }
        }

        guard let end = endIndex else { return nil }
        return String(text[first...end])
    }
}

private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
