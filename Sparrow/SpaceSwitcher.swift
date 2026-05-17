import Foundation
import CoreGraphics

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> Int32

@_silgen_name("CGSGetActiveSpace")
private func CGSGetActiveSpace(_ connection: Int32) -> Int

@_silgen_name("CGSCopyManagedDisplaySpaces")
private func CGSCopyManagedDisplaySpaces(_ connection: Int32) -> CFArray?

@_silgen_name("CGSManagedDisplaySetCurrentSpace")
private func CGSManagedDisplaySetCurrentSpace(_ connection: Int32, _ display: CFString, _ space: Int)

@_silgen_name("CGSHideSpaces")
private func CGSHideSpaces(_ connection: Int32, _ spaces: NSArray)

@_silgen_name("CGSShowSpaces")
private func CGSShowSpaces(_ connection: Int32, _ spaces: NSArray)

@_silgen_name("CGDisplayCreateUUIDFromDisplayID")
private func CGDisplayCreateUUIDFromDisplayID(_ displayID: CGDirectDisplayID) -> CFUUID?

final class SpaceSwitcher {
    enum Direction {
        case left
        case right
    }

    private var connection: Int32 {
        CGSMainConnectionID()
    }

    private let cgsEventTypeField = CGEventField(rawValue: 55)!
    private let gestureHIDTypeField = CGEventField(rawValue: 110)!
    private let gestureSwipeMotionField = CGEventField(rawValue: 123)!
    private let gestureSwipeProgressField = CGEventField(rawValue: 124)!
    private let gestureSwipeVelocityXField = CGEventField(rawValue: 129)!
    private let gestureSwipeVelocityYField = CGEventField(rawValue: 130)!
    private let gesturePhaseField = CGEventField(rawValue: 132)!

    private let cgsEventDockControl: Int64 = 30
    private let hidEventTypeDockSwipe: Int64 = 23
    private let gestureMotionHorizontal: Int64 = 1
    private let gesturePhaseBegan: Int64 = 1
    private let gesturePhaseChanged: Int64 = 2
    private let gesturePhaseEnded: Int64 = 4
    private let gestureVelocity = 950.0
    private let gestureAnimationDuration = 0.16
    private let gestureAnimationFrameCount = 10
    private let sameDirectionDebounceInterval = 0.16
    private let oppositeDirectionDebounceInterval = 0.16
    private var lastSwitchTime = Date.distantPast
    private var lastSwitchDirection: Direction?

    func switchSpace(_ direction: Direction, at location: CGPoint) {
        let elapsed = Date().timeIntervalSince(lastSwitchTime)
        let debounceInterval = direction == lastSwitchDirection
            ? sameDirectionDebounceInterval
            : oppositeDirectionDebounceInterval

        guard elapsed > debounceInterval else {
            return
        }

        let connection = connection
        guard let display = displayInfo(at: location, connection: connection) else {
            return
        }

        let targetIndex: Int
        switch direction {
        case .left:
            targetIndex = display.currentIndex - 1
        case .right:
            targetIndex = display.currentIndex + 1
        }

        guard display.spaceIDs.indices.contains(targetIndex) else {
            return
        }

        let swipeDirection = direction
        if performDockSwipe(swipeDirection) {
            lastSwitchTime = Date()
            lastSwitchDirection = direction
        } else {
            print("Failed: Dock swipe direction=\(swipeDirection) requested=\(direction) display=\(display.id) currentIndex=\(display.currentIndex) targetIndex=\(targetIndex)")
        }
    }

    private func performDockSwipe(_ direction: Direction) -> Bool {
        guard postDockSwipe(phase: gesturePhaseBegan, direction: direction, progressMagnitude: 0.0, velocityMagnitude: 0.0) else {
            return false
        }

        for frame in 1...gestureAnimationFrameCount {
            let t = Double(frame) / Double(gestureAnimationFrameCount)
            let progress = pow(t, 0.85)
            let delay = gestureAnimationDuration * t

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self else { return }
                _ = self.postDockSwipe(phase: self.gesturePhaseChanged, direction: direction, progressMagnitude: progress, velocityMagnitude: self.gestureVelocity)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + gestureAnimationDuration + (1.0 / 60.0)) { [weak self] in
            guard let self else { return }
            _ = self.postDockSwipe(phase: self.gesturePhaseEnded, direction: direction, progressMagnitude: 1.0, velocityMagnitude: 0.0)
        }

        return true
    }

    private func postDockSwipe(phase: Int64, direction: Direction, progressMagnitude: Double, velocityMagnitude: Double) -> Bool {
        guard let event = CGEvent(source: nil) else {
            return false
        }

        let isRight = direction == .right
        let progress = isRight ? progressMagnitude : -progressMagnitude
        let velocity = isRight ? velocityMagnitude : -velocityMagnitude

        event.setIntegerValueField(cgsEventTypeField, value: cgsEventDockControl)
        event.setIntegerValueField(gestureHIDTypeField, value: hidEventTypeDockSwipe)
        event.setIntegerValueField(gesturePhaseField, value: phase)
        event.setIntegerValueField(gestureSwipeMotionField, value: gestureMotionHorizontal)
        event.setDoubleValueField(gestureSwipeProgressField, value: progress)
        event.setDoubleValueField(gestureSwipeVelocityXField, value: velocity)
        event.setDoubleValueField(gestureSwipeVelocityYField, value: velocity)
        event.post(tap: .cgSessionEventTap)
        return true
    }

    private struct DisplayInfo {
        let id: String
        let spaceIDs: [Int]
        let currentIndex: Int
    }

    private func displayInfo(at location: CGPoint, connection: Int32) -> DisplayInfo? {
        guard let displays = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] else {
            return nil
        }

        let targetDisplayID = cursorDisplayID(at: location)

        guard let targetDisplayID else {
            return nil
        }

        for display in displays {
            let displayID = display["Display Identifier"] as? String ?? ""
            if displayID.caseInsensitiveCompare(targetDisplayID) != .orderedSame {
                continue
            }

            let spaces = display["Spaces"] as? [[String: Any]] ?? []
            let spaceIDs = spaces.compactMap(spaceID)
            guard let currentSpace = currentSpaceID(for: display, connection: connection),
                  let currentIndex = spaceIDs.firstIndex(of: currentSpace) else {
                continue
            }

            return DisplayInfo(id: displayID, spaceIDs: spaceIDs, currentIndex: currentIndex)
        }

        return nil
    }

    private func activeDisplayInfo(displays: [[String: Any]], connection: Int32) -> DisplayInfo? {
        let activeSpace = activeSpaceID(connection: connection)

        for display in displays {
            let displayID = display["Display Identifier"] as? String ?? ""
            let spaces = display["Spaces"] as? [[String: Any]] ?? []
            let spaceIDs = spaces.compactMap(spaceID)
            guard spaceIDs.contains(activeSpace),
                  let currentSpace = currentSpaceID(for: display, connection: connection),
                  let currentIndex = spaceIDs.firstIndex(of: currentSpace) else {
                continue
            }

            return DisplayInfo(id: displayID, spaceIDs: spaceIDs, currentIndex: currentIndex)
        }

        return nil
    }

    private func cursorDisplayID(at location: CGPoint) -> String? {
        let currentLocation = CGEvent(source: nil)?.location ?? location
        var displayID = CGDirectDisplayID()
        var displayCount: UInt32 = 0
        guard CGGetDisplaysWithPoint(currentLocation, 1, &displayID, &displayCount) == .success,
              displayCount > 0,
              let uuid = CGDisplayCreateUUIDFromDisplayID(displayID) else {
            return nil
        }

        return CFUUIDCreateString(nil, uuid) as String
    }
    private func currentSpaceID(for display: [String: Any], connection: Int32) -> Int? {
        if let currentSpace = display["Current Space"] as? [String: Any],
           let id = spaceID(currentSpace) {
            return id
        }

        return activeSpaceID(connection: connection)
    }

    private func spaceID(_ space: [String: Any]) -> Int? {
        if let id = space["ManagedSpaceID"] as? Int {
            return id
        }
        if let id64 = space["id64"] as? Int {
            return id64
        }
        return nil
    }

    private func activeSpaceID(connection: Int32) -> Int {
        guard let displays = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] else {
            return CGSGetActiveSpace(connection)
        }

        for display in displays {
            if let currentSpace = display["Current Space"] as? [String: Any],
               let spaceID = currentSpace["ManagedSpaceID"] as? Int {
                return spaceID
            }
        }

        return CGSGetActiveSpace(connection)
    }
}
