import AppKit

enum SparrowIcon {
    static let image: NSImage = {
        guard let image = NSImage(named: "SparrowMenuIcon") else {
            return NSImage(size: NSSize(width: 18, height: 18))
        }

        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }()
}
