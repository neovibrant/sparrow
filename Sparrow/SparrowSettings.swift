import Foundation
import Combine

@MainActor
final class SparrowSettings: ObservableObject {
    static let shared = SparrowSettings()

    private enum Key {
        static let moveSpaceLeftButton = "moveSpaceLeftButton"
        static let moveSpaceRightButton = "moveSpaceRightButton"
    }

    @Published var moveSpaceLeftButton: Int {
        didSet {
            UserDefaults.standard.set(moveSpaceLeftButton, forKey: Key.moveSpaceLeftButton)
        }
    }

    @Published var moveSpaceRightButton: Int {
        didSet {
            UserDefaults.standard.set(moveSpaceRightButton, forKey: Key.moveSpaceRightButton)
        }
    }

    private init() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: Key.moveSpaceLeftButton) == nil {
            defaults.set(4, forKey: Key.moveSpaceLeftButton)
        }

        if defaults.object(forKey: Key.moveSpaceRightButton) == nil {
            defaults.set(3, forKey: Key.moveSpaceRightButton)
        }

        moveSpaceLeftButton = defaults.integer(forKey: Key.moveSpaceLeftButton)
        moveSpaceRightButton = defaults.integer(forKey: Key.moveSpaceRightButton)
    }
}
