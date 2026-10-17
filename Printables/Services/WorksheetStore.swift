import Foundation
import Combine

@MainActor
final class WorksheetStore: ObservableObject {
    @Published private(set) var worksheets: [Worksheet] = []

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "printables.store", qos: .userInitiated)

    private var storeURL: URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("worksheets.json")
    }

    init(loadOnInit: Bool = true) {
        if loadOnInit {
            load()
        }
    }

    static var preview: WorksheetStore {
        let store = WorksheetStore(loadOnInit: false)
        store.worksheets = []
        return store
    }

    func add(_ worksheet: Worksheet) {
        worksheets.insert(worksheet, at: 0)
        persist()
    }

    func delete(_ worksheet: Worksheet) {
        worksheets.removeAll { $0.id == worksheet.id }
        if let imageFilename = worksheet.imageFilename {
            ImageStore.shared.deleteImage(named: imageFilename)
        }
        if let pdfFilename = worksheet.pdfFilename {
            ImageStore.shared.deletePDF(named: pdfFilename)
        }
        if let worksheetImage = worksheet.worksheetImageFilename {
            ImageStore.shared.deleteWorksheetImage(named: worksheetImage)
        }
        persist()
    }

    func update(_ worksheet: Worksheet) {
        if let idx = worksheets.firstIndex(where: { $0.id == worksheet.id }) {
            worksheets[idx] = worksheet
            persist()
        }
    }

    func toggleFavorite(_ worksheet: Worksheet) {
        guard let idx = worksheets.firstIndex(where: { $0.id == worksheet.id }) else { return }
        worksheets[idx].isFavorite.toggle()
        persist()
    }

    func deleteMany(ids: Set<UUID>) {
        let removed = worksheets.filter { ids.contains($0.id) }
        worksheets.removeAll { ids.contains($0.id) }
        for worksheet in removed {
            if let filename = worksheet.imageFilename {
                ImageStore.shared.deleteImage(named: filename)
            }
            if let pdf = worksheet.pdfFilename {
                ImageStore.shared.deletePDF(named: pdf)
            }
            if let wsImage = worksheet.worksheetImageFilename {
                ImageStore.shared.deleteWorksheetImage(named: wsImage)
            }
        }
        persist()
    }

    private func load() {
        guard fileManager.fileExists(atPath: storeURL.path),
              let data = try? Data(contentsOf: storeURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([Worksheet].self, from: data) {
            self.worksheets = decoded
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let snapshot = worksheets
        let url = storeURL
        queue.async {
            guard let data = try? encoder.encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}
