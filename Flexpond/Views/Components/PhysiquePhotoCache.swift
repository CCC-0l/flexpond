import UIKit

/// Looks up physique photos by identifier (no extension) — either a
/// bundled sample photo (the 18 sample PNGs are added to the app target as
/// flat bundle resources, see `project.yml`, found via `UIImage(named:)`'s
/// main-bundle fallback) or a user-captured photo saved to the app's
/// Documents directory. Both resolve through the same `image(named:)` call
/// so `PhysiqueEntry.photoFileNames` doesn't need to distinguish the two —
/// see `PhysiqueEntry`'s doc comment in FlexpondCore.
enum PhysiquePhotoCache {
    private static var cache: [String: UIImage] = [:]

    private static var documentsDirectory: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PhysiquePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func image(named identifier: String) -> UIImage? {
        if let cached = cache[identifier] { return cached }
        if let bundled = UIImage(named: identifier) {
            cache[identifier] = bundled
            return bundled
        }
        let url = documentsDirectory.appendingPathComponent(identifier).appendingPathExtension("jpg")
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return nil }
        cache[identifier] = image
        return image
    }

    /// Downscales, JPEG-encodes, and saves a user-captured photo to the
    /// Documents directory under `identifier`, overwriting any existing
    /// photo at that identifier (used both for a fresh capture and
    /// "replace"). Returns whether the save succeeded.
    @discardableResult
    static func save(_ image: UIImage, identifier: String) -> Bool {
        let resized = resized(image, maxDimension: 1600)
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return false }
        let url = documentsDirectory.appendingPathComponent(identifier).appendingPathExtension("jpg")
        do {
            try data.write(to: url, options: .atomic)
            cache[identifier] = resized
            return true
        } catch {
            return false
        }
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        guard scale < 1 else { return image }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
