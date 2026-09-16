import Foundation
import CoreGraphics
import ApplicationServices

class MouseRemapper {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let spaceSwitcher = SpaceSwitcher()
    private let settings = SparrowSettings.shared
    
    init() {
        startListening()
    }
    
    deinit {
        stopListening()
    }
    
    private func startListening() {
        requestAccessibilityPermissionIfNeeded()

        let eventMask = CGEventMask(1 << CGEventType.otherMouseDown.rawValue)
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: MouseRemapper.eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap. Grant Accessibility permissions.")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource!, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func requestAccessibilityPermissionIfNeeded() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let remapper = Unmanaged<MouseRemapper>.fromOpaque(userInfo).takeUnretainedValue()
        return remapper.handleEvent(type: type, event: event)
    }
    
    private func stopListening() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
    }
    
    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
        
        let leftButton = Int64(settings.moveSpaceLeftButton)
        let rightButton = Int64(settings.moveSpaceRightButton)

        if buttonNumber == leftButton || buttonNumber == rightButton {
            let location = event.location
            let direction: SpaceSwitcher.Direction = buttonNumber == leftButton ? .left : .right
            DispatchQueue.main.async { [weak self] in
                self?.spaceSwitcher.switchSpace(direction, at: location)
            }
            return nil // Swallow the original event
        }
        
        return Unmanaged.passUnretained(event)
    }
    
}
