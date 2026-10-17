import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: WorksheetStore
    @EnvironmentObject private var settings: AppSettings

    @State private var searchText: String = ""
    @State private var filter: LibraryFilter = .all
    @State private var profileFilterID: UUID? = nil
    @State private var isEditing: Bool = false
    @State private var selection: Set<UUID> = []
    @State private var showBulkDeleteConfirm = false
    @State private var bulkShareItems: [Any] = []
    @State private var showBulkShareSheet = false

    var body: some View {
        ZStack {
            CreamBackground()
            if store.worksheets.isEmpty {
                emptyState
            } else if filteredWorksheets.isEmpty {
                VStack(spacing: 0) {
                    filterStrip
                    noResultsState
                }
            } else {
                content
            }
        }
        .navigationTitle(isEditing ? "\(selection.count) selected" : "Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.worksheets.isEmpty {
                    EmptyView()
                } else if isEditing {
                    Button("Done") {
                        Haptics.shared.play(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isEditing = false
                            selection.removeAll()
                        }
                    }
                    .font(AppTheme.roundedBody(14, weight: .heavy))
                } else {
                    Button {
                        Haptics.shared.play(.light)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            isEditing = true
                        }
                    } label: {
                        Image(systemName: "checklist")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .accessibilityLabel("Select multiple worksheets")
                }
            }
        }
        .navigationDestination(for: Worksheet.self) { worksheet in
            WorksheetPreviewView(worksheet: worksheet)
        }
        .alert("Delete \(selection.count) worksheet\(selection.count == 1 ? "" : "s")?", isPresented: $showBulkDeleteConfirm) {
            Button("Delete", role: .destructive) {
                let ids = selection
                Haptics.shared.play(.warning)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    store.deleteMany(ids: ids)
                    selection.removeAll()
                    isEditing = false
                }
                ToastCenter.shared.show(.info("\(ids.count) worksheet\(ids.count == 1 ? "" : "s") removed"))
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showBulkShareSheet) {
            ShareSheet(items: bulkShareItems)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            filterStrip
            list
            if isEditing {
                bulkActionBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", systemImage: "tray.full.fill", isActive: filter == .all && profileFilterID == nil) {
                    Haptics.shared.play(.selection)
                    filter = .all
                    profileFilterID = nil
                }
                FilterChip(title: "Favorites", systemImage: "star.fill", isActive: filter == .favorites) {
                    Haptics.shared.play(.selection)
                    filter = .favorites
                }
                ForEach(settings.profiles) { profile in
                    FilterChip(
                        title: profile.greetingName,
                        systemImage: nil,
                        leadingAvatar: profile,
                        isActive: profileFilterID == profile.id
                    ) {
                        Haptics.shared.play(.selection)
                        profileFilterID = (profileFilterID == profile.id) ? nil : profile.id
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }

    private var list: some View {
        List {
            ForEach(groupedSections, id: \.title) { section in
                Section {
                    ForEach(section.worksheets) { worksheet in
                        rowFor(worksheet)
                    }
                } header: {
                    Text(section.title)
                        .font(AppTheme.roundedBody(12, weight: .heavy))
                        .foregroundStyle(AppTheme.inkSoft)
                        .kerning(1.2)
                        .textCase(nil)
                        .padding(.top, 4)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search worksheets")
        .refreshable {
            Haptics.shared.play(.light)
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
    }

    @ViewBuilder
    private func rowFor(_ worksheet: Worksheet) -> some View {
        let card = WorksheetCard(
            worksheet: worksheet,
            isSelectable: isEditing,
            isSelected: selection.contains(worksheet.id)
        )

        Group {
            if isEditing {
                Button {
                    Haptics.shared.play(.selection)
                    if selection.contains(worksheet.id) {
                        selection.remove(worksheet.id)
                    } else {
                        selection.insert(worksheet.id)
                    }
                } label: {
                    card
                }
                .buttonStyle(.plain)
            } else {
                ZStack {
                    card
                    NavigationLink(value: worksheet) { EmptyView() }.opacity(0)
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Haptics.shared.play(worksheet.isFavorite ? .light : .success)
                store.toggleFavorite(worksheet)
            } label: {
                Label(worksheet.isFavorite ? "Unfavorite" : "Favorite", systemImage: worksheet.isFavorite ? "star.slash.fill" : "star.fill")
            }
            .tint(AppTheme.sun)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Haptics.shared.play(.warning)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    store.delete(worksheet)
                }
                ToastCenter.shared.show(.info("Worksheet removed"))
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                store.toggleFavorite(worksheet)
            } label: {
                Label(worksheet.isFavorite ? "Remove from favorites" : "Add to favorites", systemImage: worksheet.isFavorite ? "star.slash" : "star")
            }
            Button {
                sharePDF(worksheet)
            } label: {
                Label("Share PDF", systemImage: "square.and.arrow.up")
            }
            Button {
                printPDF(worksheet)
            } label: {
                Label("Print", systemImage: "printer")
            }
            Divider()
            Button(role: .destructive) {
                store.delete(worksheet)
                ToastCenter.shared.show(.info("Worksheet removed"))
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var bulkActionBar: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.shared.play(.light)
                if selection.count == filteredWorksheets.count {
                    selection.removeAll()
                } else {
                    selection = Set(filteredWorksheets.map { $0.id })
                }
            } label: {
                Image(systemName: selection.count == filteredWorksheets.count ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.coral)
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(AppTheme.ink.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.scaled(haptic: nil))
            .accessibilityLabel(selection.count == filteredWorksheets.count ? "Deselect all" : "Select all")

            Spacer()

            Button {
                shareSelected()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(AppTheme.roundedBody(14, weight: .heavy))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(AppTheme.ink)
                    .background(.white)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(AppTheme.ink.opacity(0.08), lineWidth: 1))
            }
            .buttonStyle(.scaled(haptic: .light))
            .disabled(selection.isEmpty)
            .opacity(selection.isEmpty ? 0.4 : 1)

            Button(role: .destructive) {
                showBulkDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(AppTheme.roundedBody(14, weight: .heavy))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(AppTheme.coral)
                    .clipShape(Capsule())
            }
            .buttonStyle(.scaled(haptic: .warning))
            .disabled(selection.isEmpty)
            .opacity(selection.isEmpty ? 0.4 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial)
    }

    private var filteredWorksheets: [Worksheet] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return store.worksheets.filter { worksheet in
            switch filter {
            case .all: break
            case .favorites: if !worksheet.isFavorite { return false }
            }
            if let pid = profileFilterID, worksheet.profileID != pid { return false }
            if q.isEmpty { return true }
            return worksheet.content.title.lowercased().contains(q) ||
                worksheet.content.subjectLabel.lowercased().contains(q) ||
                worksheet.teachingGoal.lowercased().contains(q) ||
                worksheet.content.learningGoals.contains(where: { $0.lowercased().contains(q) })
        }
    }

    private var groupedSections: [LibrarySection] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let startOfWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday)!
        let startOfMonth = calendar.date(byAdding: .day, value: -30, to: startOfToday)!

        var today: [Worksheet] = []
        var yesterday: [Worksheet] = []
        var thisWeek: [Worksheet] = []
        var thisMonth: [Worksheet] = []
        var earlier: [Worksheet] = []

        for worksheet in filteredWorksheets {
            if worksheet.createdAt >= startOfToday {
                today.append(worksheet)
            } else if worksheet.createdAt >= startOfYesterday {
                yesterday.append(worksheet)
            } else if worksheet.createdAt >= startOfWeek {
                thisWeek.append(worksheet)
            } else if worksheet.createdAt >= startOfMonth {
                thisMonth.append(worksheet)
            } else {
                earlier.append(worksheet)
            }
        }

        var sections: [LibrarySection] = []
        if !today.isEmpty { sections.append(LibrarySection(title: "TODAY", worksheets: today)) }
        if !yesterday.isEmpty { sections.append(LibrarySection(title: "YESTERDAY", worksheets: yesterday)) }
        if !thisWeek.isEmpty { sections.append(LibrarySection(title: "THIS WEEK", worksheets: thisWeek)) }
        if !thisMonth.isEmpty { sections.append(LibrarySection(title: "THIS MONTH", worksheets: thisMonth)) }
        if !earlier.isEmpty { sections.append(LibrarySection(title: "EARLIER", worksheets: earlier)) }
        return sections
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Mascot(mood: .sleeping, size: 130)
            VStack(spacing: 8) {
                Text("Your library is napping")
                    .font(AppTheme.roundedTitle(22))
                    .foregroundStyle(AppTheme.ink)
                Text("Make your first worksheet on the Create tab and it will land here.")
                    .font(AppTheme.roundedBody(14, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
            Spacer()
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 18) {
            Spacer()
            Mascot(mood: .thinking, size: 110)
            VStack(spacing: 6) {
                Text("Nothing here yet")
                    .font(AppTheme.roundedTitle(20))
                    .foregroundStyle(AppTheme.ink)
                Text(searchText.isEmpty
                     ? "Try a different filter, or make a new worksheet."
                     : "No worksheets match \"\(searchText)\".")
                    .font(AppTheme.roundedBody(13, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            if filter != .all || profileFilterID != nil {
                Button {
                    Haptics.shared.play(.light)
                    filter = .all
                    profileFilterID = nil
                } label: {
                    Text("Clear filters")
                        .font(AppTheme.roundedBody(13, weight: .heavy))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(AppTheme.coral.opacity(0.12))
                        .foregroundStyle(AppTheme.coral)
                        .clipShape(Capsule())
                }
                .buttonStyle(.scaled(haptic: nil))
            }
            Spacer()
            Spacer()
        }
    }

    private func sharePDF(_ worksheet: Worksheet) {
        guard let filename = worksheet.pdfFilename,
              let data = ImageStore.shared.loadPDF(named: filename) else { return }
        let title = worksheet.content.title
            .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
            .joined()
            .replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(title.isEmpty ? "worksheet" : title).pdf")
        try? data.write(to: url, options: .atomic)
        bulkShareItems = [url]
        showBulkShareSheet = true
    }

    private func shareSelected() {
        let items: [URL] = selection.compactMap { id in
            guard let worksheet = store.worksheets.first(where: { $0.id == id }),
                  let filename = worksheet.pdfFilename,
                  let data = ImageStore.shared.loadPDF(named: filename) else { return nil }
            let title = worksheet.content.title
                .components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted)
                .joined()
                .replacingOccurrences(of: " ", with: "_")
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(title.isEmpty ? "worksheet" : title)-\(worksheet.id.uuidString.prefix(6)).pdf")
            try? data.write(to: url, options: .atomic)
            return url
        }
        guard !items.isEmpty else { return }
        bulkShareItems = items
        showBulkShareSheet = true
    }

    private func printPDF(_ worksheet: Worksheet) {
        guard let filename = worksheet.pdfFilename,
              let data = ImageStore.shared.loadPDF(named: filename) else { return }
        let printController = UIPrintInteractionController.shared
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = worksheet.content.title
        printController.printInfo = info
        printController.printingItem = data
        printController.present(animated: true, completionHandler: nil)
    }
}

enum LibraryFilter: Hashable {
    case all
    case favorites
}

private struct LibrarySection {
    let title: String
    let worksheets: [Worksheet]
}

private struct FilterChip: View {
    let title: String
    var systemImage: String?
    var leadingAvatar: ChildProfile?
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let profile = leadingAvatar {
                    ProfileAvatar(profile: profile, size: 18)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 11, weight: .heavy))
                }
                Text(title)
                    .font(AppTheme.roundedBody(13, weight: .heavy))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isActive ? .white : AppTheme.ink)
            .background(
                Group {
                    if isActive {
                        LinearGradient(
                            colors: [AppTheme.coral, AppTheme.coral.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color.white
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(isActive ? AppTheme.coral : AppTheme.ink.opacity(0.06), lineWidth: 1))
            .shadow(color: AppTheme.ink.opacity(isActive ? 0.10 : 0.04), radius: isActive ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(.scaled(haptic: nil))
    }
}

struct WorksheetCard: View {
    let worksheet: Worksheet
    var isSelectable: Bool = false
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            if isSelectable {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? AppTheme.coral : AppTheme.inkSoft.opacity(0.4))
                    .transition(.scale)
                    .frame(width: 28)
            }
            thumbnail

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(worksheet.content.title)
                        .font(AppTheme.roundedBody(16, weight: .heavy))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                    if worksheet.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(AppTheme.sun)
                    }
                }
                HStack(spacing: 6) {
                    Text(worksheet.content.subjectLabel)
                        .font(AppTheme.roundedBody(11, weight: .heavy))
                        .foregroundStyle(AppTheme.coral)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.coral.opacity(0.12))
                        .clipShape(Capsule())
                    if let ageRaw = worksheet.ageRangeRaw, let age = AgeRange(rawValue: ageRaw) {
                        Text(age.label)
                            .font(AppTheme.roundedBody(11, weight: .heavy))
                            .foregroundStyle(AppTheme.sky)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.sky.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(relativeDate)
                    .font(AppTheme.roundedBody(11, weight: .medium))
                    .foregroundStyle(AppTheme.inkSoft)
            }

            Spacer()
            if !isSelectable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.inkSoft.opacity(0.5))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                .strokeBorder(
                    isSelected ? AppTheme.coral : AppTheme.ink.opacity(0.04),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: AppTheme.ink.opacity(0.04), radius: 10, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(worksheet.content.title), \(worksheet.content.subjectLabel)\(worksheet.isFavorite ? ", favorite" : "")")
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: worksheet.createdAt, relativeTo: Date())
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let filename = worksheet.imageFilename,
           let image = ImageStore.shared.loadImage(named: filename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white, lineWidth: 2)
                )
                .shadow(color: AppTheme.ink.opacity(0.06), radius: 4, x: 0, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.creamDeep)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.inkSoft.opacity(0.6))
                )
        }
    }
}
