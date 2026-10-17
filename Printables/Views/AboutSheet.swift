import SwiftUI

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: WorksheetStore

    var body: some View {
        NavigationStack {
            ZStack {
                CreamBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroIcon
                        statsRow
                        infoCard
                        creditsCard
                        legalCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(AppTheme.roundedBody(15, weight: .heavy))
                }
            }
        }
    }

    private var heroIcon: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: AppTheme.coral.opacity(0.3), radius: 16, x: 0, y: 8)
                Text("P")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.coral)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(AppTheme.sun)
                    .offset(x: 36, y: -36)
            }
            Text("Printables")
                .font(AppTheme.roundedTitle(24))
                .foregroundStyle(AppTheme.ink)
            Text("for little learners")
                .font(AppTheme.roundedBody(13, weight: .heavy))
                .foregroundStyle(AppTheme.coral)
        }
        .padding(.top, 12)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(store.worksheets.count)", label: "Worksheets")
            StatTile(value: "\(store.worksheets.filter { $0.isFavorite }.count)", label: "Favorites")
            StatTile(value: "\(weeklyCount)", label: "This week")
        }
    }

    private var weeklyCount: Int {
        store.worksheets.filter {
            Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("What it does", icon: "sparkles", color: AppTheme.coral)
            Text("Printables turns any photo into a beautiful learning page for your little one. Pick a topic — or let us choose — and we'll design a one-page printable with a story, tracing, counting, coloring, and a fun fact.")
                .font(AppTheme.roundedBody(13, weight: .medium))
                .foregroundStyle(AppTheme.inkSoft)
                .lineSpacing(3)
        }
        .padding(20)
        .background(card)
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Made by", icon: "heart.fill", color: AppTheme.sun)
            Text("Crafted with love for curious minds and the grown-ups who teach them.")
                .font(AppTheme.roundedBody(13, weight: .medium))
                .foregroundStyle(AppTheme.inkSoft)
            LabeledRow(label: "AI partner", value: "OpenAI")
            LabeledRow(label: "Built with", value: "SwiftUI & PDFKit")
            LabeledRow(label: "Version", value: versionString)
        }
        .padding(20)
        .background(card)
    }

    private var legalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Links", icon: "link", color: AppTheme.sky)

            LinkRow(title: "Privacy contact", systemImage: "lock.shield.fill", url: URL(string: "mailto:chris.john.dimarco@gmail.com?subject=Printables%20Privacy"))
            LinkRow(title: "Terms of use", systemImage: "doc.text.fill", url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"))
            LinkRow(title: "Support", systemImage: "questionmark.bubble.fill", url: URL(string: "mailto:chris.john.dimarco@gmail.com?subject=Printables%20Support"))
        }
        .padding(20)
        .background(card)
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
            .fill(.white)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerLarge, style: .continuous)
                    .strokeBorder(AppTheme.ink.opacity(0.04), lineWidth: 1)
            )
            .shadow(color: AppTheme.ink.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    private func sectionTitle(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(text)
                .font(AppTheme.roundedBody(15, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
        }
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

private struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTheme.roundedTitle(22))
                .foregroundStyle(AppTheme.ink)
            Text(label)
                .font(AppTheme.roundedBody(11, weight: .heavy))
                .foregroundStyle(AppTheme.inkSoft)
                .kerning(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(AppTheme.ink.opacity(0.04), lineWidth: 1)
        )
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
        .padding(.vertical, 4)
    }
}

private struct LinkRow: View {
    let title: String
    let systemImage: String
    let url: URL?

    var body: some View {
        Group {
            if let url {
                Link(destination: url) { content }
            } else {
                content
            }
        }
        .buttonStyle(.scaled(haptic: .light))
    }

    private var content: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.sky)
                .frame(width: 22)
            Text(title)
                .font(AppTheme.roundedBody(14, weight: .heavy))
                .foregroundStyle(AppTheme.ink)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 12, weight: .heavy))
                .foregroundStyle(AppTheme.inkSoft.opacity(0.7))
        }
        .padding(.vertical, 6)
    }
}
