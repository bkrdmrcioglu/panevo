import Foundation
import AppKit
import SwiftUI

struct AnimationConstants {
    static let defaultDuration: TimeInterval = 0.3
    static let shortDuration: TimeInterval = 0.15
    static let longDuration: TimeInterval = 0.6

    static let defaultDelay: TimeInterval = 0.0

    static let springDamping: CGFloat = 0.7
    static let springStiffness: CGFloat = 0.5
}

class AnimationHelper {
    static func snapWindowAnimation(duration: TimeInterval = AnimationConstants.defaultDuration) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = duration
        NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        defer { NSAnimationContext.endGrouping() }
    }

    static func performSnapAnimation(window: NSWindow, to frame: CGRect, duration: TimeInterval = AnimationConstants.defaultDuration) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(frame, display: true)
        }
    }

    static func performFadeIn(view: NSView, duration: TimeInterval = AnimationConstants.shortDuration) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            view.animator().alphaValue = 1.0
        }
    }

    static func performFadeOut(view: NSView, duration: TimeInterval = AnimationConstants.shortDuration) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            view.animator().alphaValue = 0.0
        }
    }

    static func performScaleAnimation(view: NSView, to scale: CGFloat, duration: TimeInterval = AnimationConstants.shortDuration) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            let transform = CATransform3DMakeScale(scale, scale, 1.0)
            view.layer?.transform = transform
        }
    }

    static func performRotationAnimation(view: NSView, by angle: CGFloat, duration: TimeInterval = AnimationConstants.defaultDuration) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            let rotation = CATransform3DMakeRotation(angle, 0, 0, 1)
            view.layer?.transform = rotation
        }
    }

    static func performColorAnimation(view: NSView, to color: NSColor, duration: TimeInterval = AnimationConstants.defaultDuration) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            view.layer?.backgroundColor = color.cgColor
        }
    }
}

struct AnimationModifier: NSViewRepresentable {
    let animation: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        animation()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func performAnimation(_ animation: @escaping () -> Void) -> some View {
        self.background(AnimationModifier(animation: animation))
    }
}
