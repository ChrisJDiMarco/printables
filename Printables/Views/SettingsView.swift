import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var draftOpenAIKey: String = ""
    @State private var showSavedConfirmation = false
    @State private var showResetConfirm = false
    @State private var showAddProfile = false
    @State private var editingProfile: ChildProfile?
    @State private var showAbout = false
    @State private var showAdvancedAI = false

    var body: some View {
        ZStack {
            CreamBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    profileCard
                    styleCard
                    apiKeyCard
                    contentPrefsCard
                    appPrefsCard
                    aboutCard
                    resetCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            draftOpenAIKey = settings.openAIKey
        }
        .sheet(isPresented: $showAddProfile) {
            ProfileEditorSheet(profile: nil)
        }
        .sheet(item: $editingProfile) { profile in
            ProfileEditorSheet(profile: profile)
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
        }
        .alert("Reset onboarding?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                settings.onboardingCompleted = false
                ToastCenter.shared.show(.info("Onboarding will show next launch"))
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll see the welcome flow again the next time you open the app.")
        }
    }

    private var profileCard: some View {
        SettingsCard(
            title: "Little Learners",
            icon: "person.2.fill",
            accent: AppTheme.coral
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Each learner gets worksheets tuned to their age, with their name in the greeting.")
                    .font(AppTheme.roundedBody(13, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)
                    .padding(.bottom, 4)

                ForEach(settings.profiles) { profile in
                    Button {
                        editingProfile = profile
                    } label: {
                        HStack(spacing: 12) {
                            ProfileAvatar(profile: profile, size: 38)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(profile.hasName ? profile.name : "Unnamed")
                                        .font(AppTheme.roundedBody(14, weight: .heavy))
                                        .foregroundStyle(AppTheme.ink)
                                    if profile.id == settings.activeProfileID {
                                        Text("Active")
                                            .font(AppTheme.roundedBody(9, weight: .heavy))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(AppTheme.mint)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(profile.ageRange.label)
                                    .font(AppTheme.roundedBody(11, weight: .medium))
                                    .foregroundStyle(AppTheme.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .heavy))
                                .foregroundStyle(AppTheme.inkSoft)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.scaled(haptic: .light))
                }

                Button {
                    showAddProfile = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .heavy))
                        Text("Add another child")
                            .font(AppTheme.roundedBody(13, weight: .heavy))
                    }
                    .foregroundStyle(AppTheme.coral)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.coral.opacity(0.10))
                    .clipShape(Capsule())
                }
                .buttonStyle(.scaled(haptic: .light))
                .padding(.top, 2)
            }
        }
    }

    private var styleCard: some View {
        SettingsCard(
            title: "Default style",
            icon: "paintpalette.fill",
            accent: AppTheme.lilac
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pick the look used when you create a new worksheet. You can change it per worksheet on the Create tab.")
                    .font(AppTheme.roundedBody(13, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)

                StylePicker(selection: Binding(
                    get: { settings.defaultStyle },
                    set: { settings.defaultStyle = $0 }
                ))
                .padding(.horizontal, -20) // bleed to card edges
            }
        }
    }

    private var apiKeyCard: some View {
        SettingsCard(
            title: "OpenAI API key",
            icon: "key.fill",
            accent: AppTheme.sky,
            footer: settings.hasOpenAIKey
                ? Text("Stored securely in the device Keychain.").foregroundStyle(AppTheme.inkSoft)
                : nil
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Printables uses OpenAI's GPT Image to design your worksheets. Add your key once.")
                    .font(AppTheme.roundedBody(13, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)

                SecureField("sk-…", text: $draftOpenAIKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .font(AppTheme.roundedBody(14, weight: .medium))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(AppTheme.creamDeep)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall, style: .continuous))

                HStack(spacing: 10) {
                    Button {
                        settings.saveOpenAIKey(draftOpenAIKey)
                        ToastCenter.shared.show(.success("Key saved"))
                    } label: {
                        Text("Save key")
                            .font(AppTheme.roundedBody(14, weight: .heavy))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(AppTheme.coral)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.scaled(haptic: .success))
                    .disabled(draftOpenAIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if settings.hasOpenAIKey {
                        Button(role: .destructive) {
                            draftOpenAIKey = ""
                            settings.saveOpenAIKey("")
                            ToastCenter.shared.show(.info("Key removed"))
                        } label: {
                            Text("Remove")
                                .font(AppTheme.roundedBody(14, weight: .heavy))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .foregroundStyle(AppTheme.coral)
                                .background(AppTheme.coral.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.scaled(haptic: .warning))
                    }

                    Spacer()
                    if let url = URL(string: "https://platform.openai.com/api-keys") {
                        Link(destination: url) {
                            HStack(spacing: 4) {
                                Text("Get a key")
                                Image(systemName: "arrow.up.right")
                            }
                            .font(AppTheme.roundedBody(12, weight: .heavy))
                            .foregroundStyle(AppTheme.sky)
                        }
                    }
                }
            }
        }
    }

    private var contentPrefsCard: some View {
        SettingsCard(
            title: "Worksheet output",
            icon: "doc.text.fill",
            accent: AppTheme.mint
        ) {
            VStack(alignment: .leading, spacing: 16) {
                LabeledControl(label: "Paper size") {
                    Picker("Paper size", selection: Binding(
                        get: { settings.paperSize },
                        set: { newValue in
                            Haptics.shared.play(.selection)
                            settings.paperSize = newValue
                        }
                    )) {
                        ForEach(PaperSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                LabeledControl(label: "Image quality") {
                    Picker("Image quality", selection: Binding(
                        get: { settings.imageQuality },
                        set: { newValue in
                            Haptics.shared.play(.selection)
                            settings.imageQuality = newValue
                        }
                    )) {
                        ForEach(ImageQuality.allCases) { q in
                            Text(q.displayName).tag(q)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Text(qualityDescription)
                    .font(AppTheme.roundedBody(12, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)

                DisclosureGroup(isExpanded: $showAdvancedAI) {
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledControl(label: "Image model") {
                            TextField("gpt-image-1", text: $settings.imageModel)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(AppTheme.roundedBody(13, weight: .medium))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(AppTheme.creamDeep)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        LabeledControl(label: "Vision model") {
                            TextField("gpt-4o-mini", text: $settings.visionModel)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .font(AppTheme.roundedBody(13, weight: .medium))
                                .padding(.vertical, 10)
                                .padding(.horizontal, 12)
                                .background(AppTheme.creamDeep)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        Text("Override the OpenAI model IDs (e.g., 'gpt-image-2' when it ships).")
                            .font(AppTheme.roundedBody(11, weight: .medium))
                            .foregroundStyle(AppTheme.inkSoft)
                    }
                    .padding(.top, 8)
                } label: {
                    Text("Advanced models")
                        .font(AppTheme.roundedBody(13, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)
                }
                .tint(AppTheme.coral)
            }
        }
    }

    private var qualityDescription: String {
        switch settings.imageQuality {
        case .high: return "Highest — best detail, slower & more expensive. (Recommended)"
        case .medium: return "Balanced — good detail, reasonable speed."
        case .low: return "Fast — quicker output, lower fidelity."
        }
    }

    private var appPrefsCard: some View {
        SettingsCard(
            title: "App preferences",
            icon: "slider.horizontal.3",
            accent: AppTheme.lilac
        ) {
            VStack(spacing: 14) {
                Toggle(isOn: $settings.hapticsEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.lilac)
                            .frame(width: 24)
                        Text("Haptic feedback")
                            .font(AppTheme.roundedBody(14, weight: .heavy))
                            .foregroundStyle(AppTheme.ink)
                    }
                }
                .tint(AppTheme.coral)

                Toggle(isOn: $settings.confettiEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.sun)
                            .frame(width: 24)
                        Text("Confetti celebrations")
                            .font(AppTheme.roundedBody(14, weight: .heavy))
                            .foregroundStyle(AppTheme.ink)
                    }
                }
                .tint(AppTheme.coral)

                Toggle(isOn: Binding(
                    get: { settings.dailyReminderEnabled },
                    set: { newValue in
                        settings.dailyReminderEnabled = newValue
                        Task {
                            if newValue {
                                await NotificationManager.shared.scheduleDailyReminder()
                                ToastCenter.shared.show(.success("Daily reminder set"))
                            } else {
                                NotificationManager.shared.cancelDailyReminder()
                            }
                        }
                    }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.coral)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Daily reminder")
                                .font(AppTheme.roundedBody(14, weight: .heavy))
                                .foregroundStyle(AppTheme.ink)
                            Text("A gentle nudge at 5:30 PM")
                                .font(AppTheme.roundedBody(11, weight: .medium))
                                .foregroundStyle(AppTheme.inkSoft)
                        }
                    }
                }
                .tint(AppTheme.coral)
            }
        }
    }

    private var aboutCard: some View {
        SettingsCard(
            title: "About & support",
            icon: "heart.fill",
            accent: AppTheme.sun
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Printables turns everyday moments into beautiful learning pages for curious little minds.")
                    .font(AppTheme.roundedBody(13, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)
                    .lineSpacing(2)
                    .padding(.bottom, 4)

                Button {
                    showAbout = true
                } label: {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(AppTheme.sun)
                            .frame(width: 22)
                        Text("About this app")
                            .font(AppTheme.roundedBody(14, weight: .heavy))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.inkSoft)
                    }
                    .foregroundStyle(AppTheme.ink)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.scaled(haptic: .light))

                Divider().padding(.vertical, 2)

                LabeledRow(label: "Version", value: versionString)
            }
        }
    }

    private var resetCard: some View {
        SettingsCard(
            title: "Reset",
            icon: "arrow.counterclockwise",
            accent: AppTheme.coral
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    showResetConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .heavy))
                        Text("Replay welcome tour")
                            .font(AppTheme.roundedBody(14, weight: .heavy))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.ink)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.scaled(haptic: .light))
            }
        }
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let accent: Color
    var footer: Text?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        LinearGradient(
                            colors: [accent, accent.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                Text(title)
                    .font(AppTheme.roundedBody(16, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
            }
            content()
            if let footer {
                footer
                    .font(AppTheme.roundedBody(11, weight: .medium))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                .strokeBorder(AppTheme.ink.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: AppTheme.ink.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

private struct LabeledControl<Content: View>: View {
    let label: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppTheme.roundedBody(12, weight: .heavy))
                .foregroundStyle(AppTheme.inkSoft)
                .kerning(0.6)
            content()
        }
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppTheme.roundedBody(13, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Text(value)
                .font(AppTheme.roundedBody(13, weight: .medium))
                .foregroundStyle(AppTheme.inkSoft)
        }
    }
}

struct APIKeyEntrySheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var draftKey: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                CreamBackground()
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add your OpenAI key")
                            .font(AppTheme.roundedTitle(24))
                            .foregroundStyle(AppTheme.ink)
                        Text("Printables uses OpenAI's GPT Image to design your worksheets. Add your API key once, and we'll keep it safe in the Keychain.")
                            .font(AppTheme.roundedBody(14, weight: .medium))
                            .foregroundStyle(AppTheme.inkSoft)
                            .lineSpacing(2)
                    }

                    SecureField("sk-…", text: $draftKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(14)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerSmall, style: .continuous)
                                .strokeBorder(AppTheme.ink.opacity(0.08), lineWidth: 1)
                        )

                    if let url = URL(string: "https://platform.openai.com/api-keys") {
                        Link(destination: url) {
                            Label("Get a key from platform.openai.com", systemImage: "arrow.up.right.square")
                                .font(AppTheme.roundedBody(13, weight: .heavy))
                                .foregroundStyle(AppTheme.sky)
                        }
                    }

                    Spacer()

                    PrimaryButton("Save & continue") {
                        settings.saveOpenAIKey(draftKey)
                        ToastCenter.shared.show(.success("Key saved"))
                        dismiss()
                    }
                    .disabled(draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    SecondaryButton("Cancel") { dismiss() }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear { draftKey = settings.openAIKey }
    }
}
