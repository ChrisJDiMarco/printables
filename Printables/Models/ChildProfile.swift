import Foundation
import SwiftUI

struct ChildProfile: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var ageRange: AgeRange
    var colorRaw: String

    init(
        id: UUID = UUID(),
        name: String,
        ageRange: AgeRange,
        color: ProfileColor = .coral
    ) {
        self.id = id
        self.name = name
        self.ageRange = ageRange
        self.colorRaw = color.rawValue
    }

    var color: ProfileColor {
        ProfileColor(rawValue: colorRaw) ?? .coral
    }

    var hasName: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var greetingName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "friend" : trimmed
    }

    var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "?" }
        return String(first).uppercased()
    }

    static let placeholder = ChildProfile(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "",
        ageRange: .four_six,
        color: .coral
    )
}

enum ProfileColor: String, CaseIterable, Codable, Identifiable {
    case coral
    case sky
    case mint
    case sun
    case lilac

    var id: String { rawValue }

    var swiftUIColor: Color {
        switch self {
        case .coral: return AppTheme.coral
        case .sky: return AppTheme.sky
        case .mint: return AppTheme.mint
        case .sun: return AppTheme.sun
        case .lilac: return AppTheme.lilac
        }
    }

    var displayName: String {
        switch self {
        case .coral: return "Coral"
        case .sky: return "Sky"
        case .mint: return "Mint"
        case .sun: return "Sun"
        case .lilac: return "Lilac"
        }
    }
}

enum AgeRange: String, CaseIterable, Codable, Identifiable, Hashable {
    case two_three = "2-3"
    case four_six = "4-6"
    case seven_nine = "7-9"
    case ten_twelve = "10-12"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .two_three: return "Ages 2–3"
        case .four_six: return "Ages 4–6"
        case .seven_nine: return "Ages 7–9"
        case .ten_twelve: return "Ages 10–12"
        }
    }

    var emoji: String {
        switch self {
        case .two_three: return "🧸"
        case .four_six: return "🎨"
        case .seven_nine: return "📚"
        case .ten_twelve: return "🔬"
        }
    }

    var promptDescriptor: String {
        switch self {
        case .two_three: return "ages 2–3 (toddler, mostly visual with single letters and counting 1–3)"
        case .four_six: return "ages 4–6 (pre-K to kindergarten, simple words, counting to 10, gentle ideas)"
        case .seven_nine: return "ages 7–9 (early elementary, full sentences, basic math, comprehension questions)"
        case .ten_twelve: return "ages 10–12 (upper elementary, paragraphs, vocabulary, science concepts)"
        }
    }
}
