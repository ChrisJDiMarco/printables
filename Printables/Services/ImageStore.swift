import Foundation
import UIKit

final class ImageStore {
    static let shared = ImageStore()

    private let fileManager = FileManager.default

    private var imagesDirectory: URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("WorksheetImages", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var worksheetImageDirectory: URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("WorksheetGenerated", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var pdfDirectory: URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("WorksheetPDFs", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    @discardableResult
    func saveImage(_ image: UIImage, id: UUID) -> String? {
        let filename = "\(id.uuidString).jpg"
        let url = imagesDirectory.appendingPathComponent(filename)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    func loadImage(named filename: String) -> UIImage? {
        let url = imagesDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deleteImage(named filename: String) {
        let url = imagesDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }

    @discardableResult
    func saveWorksheetImage(_ image: UIImage, id: UUID) -> String? {
        let filename = "\(id.uuidString).png"
        let url = worksheetImageDirectory.appendingPathComponent(filename)
        guard let data = image.pngData() else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    func loadWorksheetImage(named filename: String) -> UIImage? {
        let url = worksheetImageDirectory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func deleteWorksheetImage(named filename: String) {
        let url = worksheetImageDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }

    @discardableResult
    func savePDF(_ data: Data, id: UUID) -> String? {
        let filename = "\(id.uuidString).pdf"
        let url = pdfDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    func loadPDF(named filename: String) -> Data? {
        let url = pdfDirectory.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }

    func pdfURL(for filename: String) -> URL {
        pdfDirectory.appendingPathComponent(filename)
    }

    func deletePDF(named filename: String) {
        let url = pdfDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: url)
    }
}
