import SwiftUI

struct ProfileSwitcherSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showAddProfile = false
    @State private var editingProfile: ChildProfile?

    var body: some View {
        NavigationStack {
            ZStack {
                CreamBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Pick a learner")
                            .font(AppTheme.roundedBody(12, weight: .heavy))
                            .foregroundStyle(AppTheme.inkSoft)
                            .kerning(1.4)
                            .padding(.top, 8)

                        ForEach(settings.profiles) { profile in
                            ProfileRow(
                                profile: profile,
                                isActive: profile.id == settings.activeProfileID,
                                onSelect: {
                                    Haptics.shared.play(.selection)
                                    settings.setActive(profile)
                                    dismiss()
                                },
                                onEdit: {
                                    editingProfile = profile
                                }
                            )
                        }

                        Button {
                            showAddProfile = true
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(AppTheme.creamDeep)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 18, weight: .heavy))
                                            .foregroundStyle(AppTheme.coral)
                                    )
                                    .overlay(
                                        Circle().strokeBorder(AppTheme.coral.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                    )
                                Text("Add another child")
                                    .font(AppTheme.roundedBody(15, weight: .heavy))
                                    .foregroundStyle(AppTheme.ink)
                                Spacer()
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                                    .fill(.white)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                                    .strokeBorder(AppTheme.ink.opacity(0.04), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.scaled(haptic: .light))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Learners")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.roundedBody(15, weight: .heavy))
                }
            }
            .sheet(isPresented: $showAddProfile) {
                ProfileEditorSheet(profile: nil)
            }
            .sheet(item: $editingProfile) { profile in
                ProfileEditorSheet(profile: profile)
            }
        }
    }
}

private struct ProfileRow: View {
    let profile: ChildProfile
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                ProfileAvatar(profile: profile, size: 44, showRing: isActive)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(profile.hasName ? profile.name : "Unnamed")
                            .font(AppTheme.roundedBody(16, weight: .heavy))
                            .foregroundStyle(AppTheme.ink)
                        if isActive {
                            Text("Active")
                                .font(AppTheme.roundedBody(10, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.mint)
                                .clipShape(Capsule())
                        }
                    }
                    Text(profile.ageRange.label)
                        .font(AppTheme.roundedBody(12, weight: .medium))
                        .foregroundStyle(AppTheme.inkSoft)
                }

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.inkSoft)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.creamDeep)
                        .clipShape(Circle())
                }
                .buttonStyle(.scaled(haptic: .light))
                .accessibilityLabel("Edit \(profile.name) profile")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                    .fill(.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerMedium, style: .continuous)
                    .strokeBorder(
                        isActive ? profile.color.swiftUIColor.opacity(0.4) : AppTheme.ink.opacity(0.04),
                        lineWidth: isActive ? 2 : 1
                    )
            )
            .shadow(color: AppTheme.ink.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.scaled(haptic: .light))
    }
}

struct ProfileEditorSheet: View {
    let profile: ChildProfile?
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var ageRange: AgeRange = .four_six
    @State private var color: ProfileColor = .coral
    @State private var showDeleteConfirm = false

    private var isEditing: Bool { profile != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                CreamBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        ProfileAvatar(
                            profile: ChildProfile(name: name, ageRange: ageRange, color: color),
                            size: 96
                        )
                        .shadow(color: color.swiftUIColor.opacity(0.35), radius: 12, x: 0, y: 6)
                        .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(AppTheme.roundedBody(13, weight: .heavy))
                                .foregroundStyle(AppTheme.inkSoft)

                            TextField("First name", text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled(true)
                                .font(AppTheme.roundedBody(15, weight: .medium))
                                .padding(14)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(AppTheme.ink.opacity(0.06), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Age range")
                                .font(AppTheme.roundedBody(13, weight: .heavy))
                                .foregroundStyle(AppTheme.inkSoft)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                                ForEach(AgeRange.allCases) { range in
                                    Button {
                                        Haptics.shared.play(.selection)
                                        ageRange = range
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(range.emoji)
                                            Text(range.label)
                                                .font(AppTheme.roundedBody(14, weight: .heavy))
                                            Spacer()
                                            if ageRange == range {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundStyle(color.swiftUIColor)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(AppTheme.ink)
                                        .background(ageRange == range ? color.swiftUIColor.opacity(0.10) : .white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(
                                                    ageRange == range ? color.swiftUIColor : AppTheme.ink.opacity(0.06),
                                                    lineWidth: ageRange == range ? 2 : 1
                                                )
                                        )
                                    }
                                    .buttonStyle(.scaled(haptic: nil))
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Color")
                                .font(AppTheme.roundedBody(13, weight: .heavy))
                                .foregroundStyle(AppTheme.inkSoft)

                            HStack(spacing: 12) {
                                ForEach(ProfileColor.allCases) { c in
                                    Button {
                                        Haptics.shared.play(.selection)
                                        color = c
                                    } label: {
                                        Circle()
                                            .fill(c.swiftUIColor)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle().strokeBorder(.white, lineWidth: 2)
                                            )
                                            .overlay(
                                                Circle().strokeBorder(
                                                    color == c ? AppTheme.ink : Color.clear,
                                                    lineWidth: 2
                                                )
                                                .padding(-4)
                                            )
                                            .accessibilityLabel("\(c.displayName) color")
                                    }
                                    .buttonStyle(.scaled(haptic: nil))
                                }
                                Spacer()
                            }
                        }

                        if isEditing && settings.profiles.count > 1 {
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Text("Remove this profile")
                                    .font(AppTheme.roundedBody(14, weight: .heavy))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .foregroundStyle(AppTheme.coral)
                                    .background(AppTheme.coral.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.scaled(haptic: .warning))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Edit learner" : "New learner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .font(AppTheme.roundedBody(15, weight: .heavy))
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Remove this profile?", isPresented: $showDeleteConfirm) {
                Button("Remove", role: .destructive) {
                    if let p = profile {
                        settings.removeProfile(p)
                        ToastCenter.shared.show(.info("Profile removed"))
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Worksheets made for this learner will stay in your library.")
            }
            .onAppear(perform: loadInitial)
        }
    }

    private func loadInitial() {
        if let p = profile {
            name = p.name
            ageRange = p.ageRange
            color = p.color
        }
    }

    private func save() {
        Haptics.shared.play(.success)
        if var existing = profile {
            existing.name = name
            existing.ageRange = ageRange
            existing.colorRaw = color.rawValue
            settings.updateProfile(existing)
            ToastCenter.shared.show(.success("Profile updated"))
        } else {
            let added = settings.addProfile(name: name, ageRange: ageRange, color: color)
            settings.setActive(added)
            ToastCenter.shared.show(.success("\(added.greetingName) added"))
        }
        dismiss()
    }
}
