import Foundation
import Combine
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    private static let onboardingCompletedKey = "printables.onboardingCompleted"
    private static let defaultPaperKey = "printables.paperSize"
    private static let hapticsEnabledKey = "printables.hapticsEnabled"
    private static let confettiEnabledKey = "printables.confettiEnabled"
    private static let dailyReminderEnabledKey = "printables.dailyReminderEnabled"
    private static let profilesKey = "printables.profiles.v2"
    private static let activeProfileIDKey = "printables.activeProfileID"
    private static let legacyNameKey = "printables.profile.name"
    private static let legacyAgeKey = "printables.profile.age"
    private static let recentTopicsKey = "printables.recentTopics"
    private static let imageModelKey = "printables.imageModel"
    private static let visionModelKey = "printables.visionModel"
    private static let imageQualityKey = "printables.imageQuality"
    private static let defaultStyleKey = "printables.defaultStyle"

    @AppStorage(onboardingCompletedKey) var onboardingCompleted: Bool = false
    @AppStorage(defaultPaperKey) var paperSizeRaw: String = PaperSize.letter.rawValue
    @AppStorage(imageModelKey) var imageModel: String = "gpt-image-1"
    @AppStorage(visionModelKey) var visionModel: String = "gpt-4o-mini"
    @AppStorage(imageQualityKey) var imageQualityRaw: String = ImageQuality.high.rawValue
    @AppStorage(defaultStyleKey) var defaultStyleRaw: String = WorksheetStyle.default.rawValue
    @AppStorage(hapticsEnabledKey) var hapticsEnabled: Bool = true {
        didSet {
            Task { @MainActor in
                Haptics.shared.isEnabled = hapticsEnabled
            }
        }
    }
    @AppStorage(confettiEnabledKey) var confettiEnabled: Bool = true
    @AppStorage(dailyReminderEnabledKey) var dailyReminderEnabled: Bool = false

    @Published var openAIKey: String
    @Published private(set) var profiles: [ChildProfile] = []
    @Published var activeProfileID: UUID?
    @Published var recentTopics: [String] = []

    private let defaults = UserDefaults.standard

    init() {
        self.openAIKey = KeychainStore.shared.read(forKey: KeychainStore.openAIKeyName) ?? ""

        Task { @MainActor in
            Haptics.shared.isEnabled = self.hapticsEnabled
        }

        loadProfiles()
        migrateLegacyProfileIfNeeded()
        loadActiveProfileID()
        loadRecentTopics()
    }

    var shouldShowOnboarding: Bool {
        get { !onboardingCompleted }
        set { onboardingCompleted = !newValue }
    }

    var paperSize: PaperSize {
        get { PaperSize(rawValue: paperSizeRaw) ?? .letter }
        set { paperSizeRaw = newValue.rawValue }
    }

    func saveOpenAIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        openAIKey = trimmed
        if trimmed.isEmpty {
            KeychainStore.shared.delete(forKey: KeychainStore.openAIKeyName)
        } else {
            KeychainStore.shared.save(trimmed, forKey: KeychainStore.openAIKeyName)
        }
    }

    var hasOpenAIKey: Bool {
        !openAIKey.isEmpty
    }

    var imageQuality: ImageQuality {
        get { ImageQuality(rawValue: imageQualityRaw) ?? .high }
        set { imageQualityRaw = newValue.rawValue }
    }

    var defaultStyle: WorksheetStyle {
        get { WorksheetStyle(rawValue: defaultStyleRaw) ?? .pastel }
        set { defaultStyleRaw = newValue.rawValue }
    }

    // MARK: - Profiles

    var activeProfile: ChildProfile {
        if let id = activeProfileID, let match = profiles.first(where: { $0.id == id }) {
            return match
        }
        return profiles.first ?? ChildProfile.placeholder
    }

    func addProfile(name: String, ageRange: AgeRange, color: ProfileColor) -> ChildProfile {
        let profile = ChildProfile(name: name, ageRange: ageRange, color: color)
        profiles.append(profile)
        persistProfiles()
        if profiles.count == 1 {
            activeProfileID = profile.id
            persistActiveProfileID()
        }
        return profile
    }

    func updateProfile(_ profile: ChildProfile) {
        guard let idx = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[idx] = profile
        persistProfiles()
    }

    func removeProfile(_ profile: ChildProfile) {
        profiles.removeAll { $0.id == profile.id }
        if activeProfileID == profile.id {
            activeProfileID = profiles.first?.id
            persistActiveProfileID()
        }
        persistProfiles()
    }

    func setActive(_ profile: ChildProfile) {
        guard profiles.contains(where: { $0.id == profile.id }) else { return }
        activeProfileID = profile.id
        persistActiveProfileID()
    }

    private func loadProfiles() {
        guard let data = defaults.data(forKey: Self.profilesKey) else { return }
        if let decoded = try? JSONDecoder().decode([ChildProfile].self, from: data) {
            self.profiles = decoded
        }
    }

    private func persistProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: Self.profilesKey)
        }
    }

    private func loadActiveProfileID() {
        if let raw = defaults.string(forKey: Self.activeProfileIDKey),
           let id = UUID(uuidString: raw) {
            self.activeProfileID = id
        } else {
            self.activeProfileID = profiles.first?.id
        }
    }

    private func persistActiveProfileID() {
        if let id = activeProfileID {
            defaults.set(id.uuidString, forKey: Self.activeProfileIDKey)
        } else {
            defaults.removeObject(forKey: Self.activeProfileIDKey)
        }
    }

    private func migrateLegacyProfileIfNeeded() {
        guard profiles.isEmpty else { return }
        let legacyName = defaults.string(forKey: Self.legacyNameKey) ?? ""
        let legacyAge = AgeRange(rawValue: defaults.string(forKey: Self.legacyAgeKey) ?? "") ?? .four_six
        if !legacyName.isEmpty || onboardingCompleted {
            let migrated = ChildProfile(name: legacyName, ageRange: legacyAge, color: .coral)
            profiles = [migrated]
            persistProfiles()
            activeProfileID = migrated.id
            persistActiveProfileID()
        }
    }

    // MARK: - Recent topics

    func recordTopic(_ topic: String) {
        let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var working = recentTopics.filter { $0.lowercased() != trimmed.lowercased() }
        working.insert(trimmed, at: 0)
        recentTopics = Array(working.prefix(8))
        persistRecentTopics()
    }

    func clearRecentTopics() {
        recentTopics = []
        persistRecentTopics()
    }

    private func loadRecentTopics() {
        if let arr = defaults.array(forKey: Self.recentTopicsKey) as? [String] {
            self.recentTopics = arr
        }
    }

    private func persistRecentTopics() {
        defaults.set(recentTopics, forKey: Self.recentTopicsKey)
    }
}

enum PaperSize: String, CaseIterable, Identifiable {
    case letter
    case a4

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .letter: return "US Letter"
        case .a4: return "A4"
        }
    }

    var detailedDisplayName: String {
        switch self {
        case .letter: return "US Letter (8.5 × 11 in)"
        case .a4: return "A4 (210 × 297 mm)"
        }
    }

    var pointsSize: CGSize {
        switch self {
        case .letter: return CGSize(width: 612, height: 792)
        case .a4: return CGSize(width: 595, height: 842)
        }
    }
}
