import Foundation
import CoreGraphics

class MouseRemapper {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let spaceSwitcher = SpaceSwitcher()
    
    // macOS virtual key codes
    private let kVK_Control: CGKeyCode = 0x3B
    private let kVK_ArrowLeft: CGKeyCode = 0x7B
    private let kVK_ArrowRight: CGKeyCode = 0x7C
    
    init() {
        startListening()
    }
    
    deinit {
        stopListening()
    }
    
    private func startListening() {
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
        
        print("Sparrow is listening for mouse events...")
    }

    private static let eventTapCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }

        let remapper = Unmanaged<MouseRemapper>.fromOpaque(userInfo).takeUnretainedValue()
        let button = event.getIntegerValueField(.mouseEventButtonNumber)
        print("Tap: type=\(type.rawValue) button=\(button)")
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
        
        // Button 3 = Back (Mouse Button 4)
        // Button 4 = Forward (Mouse Button 5)
        if buttonNumber == 3 || buttonNumber == 4 {
            let location = event.location
            DispatchQueue.main.async { [weak self] in
                self?.spaceSwitcher.switchSpace(buttonNumber == 3 ? .right : .left, at: location)
            }
            return nil // Swallow the original event
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func postSpaceSwitch(keyCode: CGKeyCode) {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("Failed to create event source")
            return
        }

        let controlDown = CGEvent(keyboardEventSource: source, virtualKey: kVK_Control, keyDown: true)
        controlDown?.flags = CGEventFlags.maskControl
        controlDown?.post(tap: .cghidEventTap)
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = [CGEventFlags.maskControl, CGEventFlags.maskNumericPad]
        keyDown?.post(tap: .cghidEventTap)
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = [CGEventFlags.maskControl, CGEventFlags.maskNumericPad]
        keyUp?.post(tap: .cghidEventTap)

        let controlUp = CGEvent(keyboardEventSource: source, virtualKey: kVK_Control, keyDown: false)
        controlUp?.flags = []
        controlUp?.post(tap: .cghidEventTap)
        
        print("Posted space switch: \(keyCode == kVK_ArrowLeft ? "left" : "right")")
    }
}
