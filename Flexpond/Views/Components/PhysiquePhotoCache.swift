import UIKit

/// Looks up bundled physique sample photos by filename (no extension). The
/// 18 sample PNGs are added to the app target as flat bundle resources (see
/// `project.yml`), so `UIImage(named:)`'s main-bundle fallback finds them
/// directly — no asset catalog entries needed.
enum PhysiquePhotoCache {
    private static var cache: [String: UIImage] = [:]

    static func image(named fileName: String) -> UIImage? {
        if let cached = cache[fileName] { return cached }
        guard let image = UIImage(named: fileName) else { return nil }
        cache[fileName] = image
        return image
    }
}
