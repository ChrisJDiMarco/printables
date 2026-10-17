import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject private var store: WorksheetStore
    @EnvironmentObject private var settings: AppSettings

    @State private var selectedImage: UIImage?
    @State private var teachingGoal: String = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showCameraDeniedAlert = false
    @State private var showAPIKeyPrompt = false
    @State private var showPhotosPicker = false
    @State private var showStyleSheet = false
    @State private var showProfileSheet = false
    @State private var generator: WorksheetGenerator?
    @State private var navigateToPreview = false
    @State private var presentedWorksheet: Worksheet?
    @State private var pickedStyle: WorksheetStyle = .pastel
    @State private var emptyPhotoFloat: Bool = false
    @FocusState private var topicFocused: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let suggestions: [(display: String, topic: String, icon: String, color: Color)] = [
        ("Letters", "Letter sounds and tracing", "textformat.abc", AppTheme.coral),
        ("Numbers", "Counting and colors", "1.circle.fill", AppTheme.sky),
        ("Healthy food", "Healthy eating habits", "leaf.fill", AppTheme.mint),
        ("Safety", "Safety basics", "shield.fill", AppTheme.sun),
        ("Animals", "Animal habitats", "pawprint.fill", AppTheme.lilac)
    ]

    var body: some View {
        ZStack {
            CreamBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerStrip
                    heroCard
                    recentTopicsCard
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(image: $selectedImage)
                .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $photoItem,
            matching: .images,
            preferredItemEncoding: .automatic
        )
        .onChange(of: photoItem) { _, newValue in
            handlePhotoSelection(newValue)
        }
        .alert("Camera access needed", isPresented: $showCameraDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow camera access so kids can snap a learning moment.")
        }
        .sheet(isPresented: $showAPIKeyPrompt) {
            APIKeyEntrySheet()
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileSwitcherSheet()
        }
        .sheet(isPresented: $showStyleSheet) {
            StyleSheet(selection: $pickedStyle)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .navigationDestination(isPresented: $navigateToPreview) {
            if let worksheet = presentedWorksheet {
                WorksheetPreviewView(worksheet: worksheet, celebrate: true)
            }
        }
        .fullScreenCover(item: Binding(
            get: { generator.flatMap { gen -> GeneratorWrapper? in
                switch gen.stage {
                case .idle, .done, .cancelled: return nil
                default: return GeneratorWrapper(generator: gen)
                }
            } },
            set: { _ in }
        )) { wrapper in
            GenerationProgressView(generator: wrapper.generator)
                .interactiveDismissDisabled(true)
        }
        .onChange(of: stageDescription) { _, _ in
            handleStageChange()
        }
        .onAppear {
            pickedStyle = settings.defaultStyle
        }
    }

    // MARK: - Header

    private var headerStrip: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(timeOfDayGreeting)
                        .font(AppTheme.roundedBody(11, weight: .heavy))
                        .foregroundStyle(settings.activeProfile.color.swiftUIColor)
                        .kerning(0.8)
                    Text(greetingLine)
                        .font(AppTheme.roundedTitle(24))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                if weeklyCount > 0 {
                    streakChip
                }
            }
            Spacer()
            profileChip
        }
        .padding(.top, 4)
    }

    private var streakChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .heavy))
                .foregroundStyle(AppTheme.coral)
            Text("\(weeklyCount) this week")
                .font(AppTheme.roundedBody(11, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(AppTheme.sun.opacity(0.22))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(AppTheme.sun.opacity(0.5), lineWidth: 1))
        .accessibilityLabel("\(weeklyCount) worksheets this week")
    }

    private var weeklyCount: Int {
        store.worksheets.filter {
            Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
    }

    @ViewBuilder
    private var profileChip: some View {
        if settings.profiles.isEmpty {
            AddLearnerPill { showProfileSheet = true }
        } else {
            ProfileSwitcherPill(
                profile: settings.activeProfile,
                totalProfiles: settings.profiles.count
            ) {
                showProfileSheet = true
            }
        }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        VStack(spacing: 14) {
            photoZone
            topicSection
            StyleChip(style: pickedStyle) { showStyleSheet = true }
            createButton
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(AppTheme.ink.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: AppTheme.ink.opacity(0.06), radius: 22, x: 0, y: 10)
    }

    // MARK: - Photo zone

    @ViewBuilder
    private var photoZone: some View {
        if let image = selectedImage {
            selectedPhoto(image)
        } else {
            emptyPhotoZone
        }
    }

    private var emptyPhotoZone: some View {
        Menu {
            Button {
                startCamera()
            } label: {
                Label("Take Photo", systemImage: "camera.fill")
            }
            Button {
                showPhotosPicker = true
            } label: {
                Label("Choose from Library", systemImage: "photo.on.rectangle.angled")
            }
            Button {
                pasteImageFromClipboard()
            } label: {
                Label("Paste", systemImage: "doc.on.clipboard")
            }
        } label: {
            ZStack {
                emptyPhotoBackdrop

                emptyPhotoSparkles

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.coral.opacity(0.14))
                            .frame(width: 76, height: 76)
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.coral, AppTheme.coral.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: AppTheme.coral.opacity(0.35), radius: 10, x: 0, y: 5)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    .offset(y: emptyPhotoFloat && !reduceMotion ? -3 : 3)

                    VStack(spacing: 3) {
                        Text("Add a photo")
                            .font(AppTheme.roundedTitle(18))
                            .foregroundStyle(AppTheme.ink)
                        Text("Camera, library, or paste from clipboard")
                            .font(AppTheme.roundedBody(12, weight: .medium))
                            .foregroundStyle(AppTheme.inkSoft)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            }
            .frame(maxWidth: .infinity)
        }
        .menuOrder(.fixed)
        .accessibilityLabel("Add a photo. Tap to choose camera, library, or paste.")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                emptyPhotoFloat = true
            }
        }
    }

    private var emptyPhotoBackdrop: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppTheme.creamDeep.opacity(0.55))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        AppTheme.coral.opacity(0.32),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                    )
            )
    }

    private var emptyPhotoSparkles: some View {
        ZStack {
            sparkle(systemName: "sparkle", size: 14, color: AppTheme.sun, offset: CGSize(width: -130, height: -64))
            sparkle(systemName: "sparkles", size: 16, color: AppTheme.coral, offset: CGSize(width: 132, height: -52))
            sparkle(systemName: "sparkle", size: 11, color: AppTheme.sky, offset: CGSize(width: -118, height: 64))
            sparkle(systemName: "sparkle", size: 13, color: AppTheme.lilac, offset: CGSize(width: 124, height: 70))
        }
        .accessibilityHidden(true)
    }

    private func sparkle(systemName: String, size: CGFloat, color: Color, offset: CGSize) -> some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .heavy))
            .foregroundStyle(color.opacity(0.65))
            .offset(offset)
    }

    private func selectedPhoto(_ image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            HStack(spacing: 8) {
                Button {
                    startCamera()
                } label: {
                    Label("Retake", systemImage: "camera.rotate.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.55))
                        .clipShape(Circle())
                }
                .buttonStyle(.scaled(haptic: .light))
                .accessibilityLabel("Retake photo")

                Button {
                    Haptics.shared.play(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        selectedImage = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.55))
                        .clipShape(Circle())
                }
                .buttonStyle(.scaled(haptic: nil))
                .accessibilityLabel("Remove photo")
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .transition(.scale(scale: 0.96).combined(with: .opacity))
    }

    // MARK: - Topic + suggestions

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("What to teach")
                    .font(AppTheme.roundedBody(14, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                if !teachingGoal.isEmpty {
                    Button {
                        Haptics.shared.play(.light)
                        teachingGoal = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.inkSoft.opacity(0.5))
                    }
                    .accessibilityLabel("Clear topic")
                }
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                topicFocused ? AppTheme.coral.opacity(0.4) : AppTheme.ink.opacity(0.10),
                                lineWidth: topicFocused ? 1.5 : 1
                            )
                    )

                if teachingGoal.isEmpty {
                    Text("e.g. Letter A, fire-truck safety, or leave blank to surprise us")
                        .font(AppTheme.roundedBody(13, weight: .medium))
                        .foregroundStyle(AppTheme.inkSoft.opacity(0.55))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextField("", text: $teachingGoal, axis: .vertical)
                    .focused($topicFocused)
                    .font(AppTheme.roundedBody(14, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1...3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
            .frame(minHeight: 48)

            FlowLayout(spacing: 7) {
                ForEach(suggestions, id: \.display) { item in
                    suggestionPill(item)
                }
            }
        }
    }

    private func suggestionPill(_ item: (display: String, topic: String, icon: String, color: Color)) -> some View {
        Button {
            Haptics.shared.play(.selection)
            teachingGoal = item.topic
        } label: {
            HStack(spacing: 5) {
                Image(systemName: item.icon)
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 17, height: 17)
                    .background(item.color)
                    .clipShape(Circle())
                Text(item.display)
                    .font(AppTheme.roundedBody(12, weight: .heavy))
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [item.color.opacity(0.18), item.color.opacity(0.10)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(item.color.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.scaled(haptic: nil))
        .accessibilityLabel("Suggestion: \(item.topic)")
    }

    // MARK: - Create CTA

    @ViewBuilder
    private var createButton: some View {
        if selectedImage == nil {
            Menu {
                Button {
                    startCamera()
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                }
                Button {
                    showPhotosPicker = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.on.rectangle.angled")
                }
                Button {
                    pasteImageFromClipboard()
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
            } label: {
                disabledCreateHint
            }
            .menuOrder(.fixed)
            .accessibilityLabel("Pick a photo to begin")
        } else {
            Button {
                attemptGenerate()
            } label: {
                activeCreateButton
            }
            .buttonStyle(.scaled(haptic: .medium))
            .accessibilityLabel("Create worksheet")
        }
    }

    private var disabledCreateHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.up")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(AppTheme.coral.opacity(0.7))
            Text("Pick a photo above to begin")
                .font(AppTheme.roundedBody(14, weight: .heavy))
                .foregroundStyle(AppTheme.inkSoft)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .strokeBorder(
                    AppTheme.coral.opacity(0.30),
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                )
        )
    }

    private var activeCreateButton: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .heavy))
            Text("Create worksheet")
                .font(AppTheme.roundedBody(16, weight: .heavy))
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [AppTheme.coral, AppTheme.coral.opacity(0.86)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: AppTheme.coral.opacity(0.30), radius: 14, x: 0, y: 7)
    }

    // MARK: - Recent topics

    @ViewBuilder
    private var recentTopicsCard: some View {
        if !settings.recentTopics.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11, weight: .heavy))
                    Text("RECENT")
                        .font(AppTheme.roundedBody(11, weight: .heavy))
                        .kerning(1.4)
                    Spacer()
                    Button("Clear") {
                        Haptics.shared.play(.light)
                        settings.clearRecentTopics()
                    }
                    .font(AppTheme.roundedBody(11, weight: .heavy))
                    .foregroundStyle(AppTheme.inkSoft)
                }
                .foregroundStyle(AppTheme.mint)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(settings.recentTopics, id: \.self) { topic in
                            Button {
                                Haptics.shared.play(.selection)
                                teachingGoal = topic
                            } label: {
                                Text(topic)
                                    .font(AppTheme.roundedBody(13, weight: .heavy))
                                    .foregroundStyle(AppTheme.ink)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.white)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(AppTheme.ink.opacity(0.06), lineWidth: 1))
                            }
                            .buttonStyle(.scaled(haptic: nil))
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.creamDeep.opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(AppTheme.ink.opacity(0.04), lineWidth: 1)
            )
        }
    }

    // MARK: - Helpers

    private var greetingLine: String {
        let profile = settings.activeProfile
        guard profile.hasName else { return "Let's make something." }
        let name = profile.greetingName
        let options = [
            "Hi, \(name)!",
            "Hey, \(name)!",
            "Ready, \(name)?",
            "Welcome back, \(name).",
            "What's next, \(name)?",
            "Let's go, \(name)!"
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return options[dayOfYear % options.count]
    }

    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        case 17..<22: return "GOOD EVENING"
        default: return "HELLO, NIGHT OWL"
        }
    }

    private var stageDescription: String {
        guard let stage = generator?.stage else { return "idle" }
        switch stage {
        case .idle: return "idle"
        case .analyzing: return "analyzing"
        case .writing: return "writing"
        case .rendering: return "rendering"
        case .done: return "done"
        case .failed(let msg): return "failed:\(msg)"
        case .cancelled: return "cancelled"
        }
    }

    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    Haptics.shared.play(.soft)
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        selectedImage = image.normalizedOrientation()
                    }
                }
            }
            await MainActor.run { photoItem = nil }
        }
    }

    private func pasteImageFromClipboard() {
        if let image = UIPasteboard.general.image {
            Haptics.shared.play(.success)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                selectedImage = image.normalizedOrientation()
            }
        } else {
            ToastCenter.shared.show(.info("No image on clipboard"))
        }
    }

    private func startCamera() {
        CameraPermission.requestAccess { granted in
            if granted {
                showCamera = true
            } else {
                showCameraDeniedAlert = true
            }
        }
    }

    private func attemptGenerate() {
        guard let image = selectedImage else { return }
        guard settings.hasOpenAIKey else {
            showAPIKeyPrompt = true
            return
        }
        guard !settings.profiles.isEmpty else {
            ToastCenter.shared.show(.info("Add a learner first"))
            showProfileSheet = true
            return
        }
        if !teachingGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            settings.recordTopic(teachingGoal)
        }
        let gen = WorksheetGenerator(store: store, paperSize: settings.paperSize)
        self.generator = gen
        gen.generate(
            image: image,
            teachingGoal: teachingGoal,
            profile: settings.activeProfile,
            style: pickedStyle,
            openAIKey: settings.openAIKey,
            visionModel: settings.visionModel,
            imageModel: settings.imageModel,
            quality: settings.imageQuality
        )
    }

    private func handleStageChange() {
        guard let stage = generator?.stage else { return }
        switch stage {
        case .done(let worksheet):
            Haptics.shared.play(.success)
            ToastCenter.shared.show(.success("Worksheet ready!", message: "Tap Print or Share to send it out."))
            presentedWorksheet = worksheet
            navigateToPreview = true
            generator = nil
            selectedImage = nil
            teachingGoal = ""
        case .failed(let msg):
            ToastCenter.shared.show(.error("Couldn't generate", message: msg))
            generator = nil
        case .cancelled:
            ToastCenter.shared.show(.info("Generation cancelled"))
            generator = nil
        default:
            break
        }
    }
}

private struct GeneratorWrapper: Identifiable {
    let id = UUID()
    let generator: WorksheetGenerator
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(WorksheetStore.preview)
            .environmentObject(AppSettings())
    }
}
