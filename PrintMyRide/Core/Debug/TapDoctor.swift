import SwiftUI
import Combine
import os

private let tlog = Logger(subsystem: "com.printmyride.tapdoctor", category: "scan")

final class TapDoctor {
    static let shared = TapDoctor()
    private var timer: AnyCancellable?
    private init() {}

    func enableAutoScanAndFix(interval: TimeInterval = 1.0) {
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.scanAndFix() }
        tlog.info("TapDoctor enabled")
    }

    func scanAndFix() {
        guard let root = TapDoctor.rootUIView() else { return }
        let all = TapDoctor.flatten(root)
        let tappables = all.filter { $0.isIntendedTappable }
        for v in tappables {
            let frame = v.windowFrame
            
            // Skip iOS status bar area (top 100 points to include dynamic island)
            if frame.origin.y < 100 { continue }
            
            let tooSmall = frame.size.width < 44 || frame.size.height < 44
            let blocked = TapDoctor.isBlocked(view: v, among: all)
            let missingShape = v.isSwiftUIButton && !v.hasContentShape

            if tooSmall || blocked || missingShape {
                TapDoctor.annotate(frame: frame, reason: TapDoctor.reason(tooSmall, blocked, missingShape))
                #if DEBUG
                TapDoctor.applyFixes(view: v, tooSmall: tooSmall, blocked: blocked, missingShape: missingShape)
                #endif
                tlog.info("Tap issue: \(TapDoctor.reason(tooSmall, blocked, missingShape)) at \(String(describing: frame))")
            }
        }
    }

    private static func reason(_ small: Bool, _ blocked: Bool, _ missing: Bool) -> String {
        var r: [String] = []
        if small { r.append("hit area < 44x44") }
        if blocked { r.append("covered by overlay") }
        if missing { r.append("missing contentShape") }
        return r.joined(separator: " • ")
    }

    // MARK: UIKit plumbing

    static func rootUIView() -> UIView? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?.view
    }

    static func flatten(_ v: UIView) -> [UIView] {
        [v] + v.subviews.flatMap { flatten($0) }
    }

    static func isBlocked(view: UIView, among all: [UIView]) -> Bool {
        guard let window = view.window else { return false }
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        let pt = view.convert(center, to: window)
        let hit = window.hitTest(pt, with: nil)
        return hit != nil && hit !== view && hit?.isActuallyHittable == true
    }

    static func annotate(frame: CGRect, reason: String) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return }
        let overlay = TDOverlay(frame: frame.insetBy(dx: -2, dy: -2))
        overlay.reason = reason
        window.addSubview(overlay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { overlay.removeFromSuperview() }
    }

    static func applyFixes(view: UIView, tooSmall: Bool, blocked: Bool, missingShape: Bool) {
        // 1) Expand hit area with an invisible proxy
        if tooSmall {
            let padView = UIControl(frame: view.bounds.insetBy(dx: -max(0, 44 - view.bounds.width)/2,
                                                               dy: -max(0, 44 - view.bounds.height)/2))
            padView.backgroundColor = .clear
            padView.isOpaque = false
            padView.isExclusiveTouch = false
            padView.addTarget(nil, action: #selector(UIView._td_passthroughTap), for: .touchUpInside)
            padView.tag = 990_001
            padView.isUserInteractionEnabled = true
            view.addSubview(padView)
        }
        // 2) Neutralize decorative blockers above
        if blocked {
            // Walk up and mark clearly non-control siblings as non-hittable
            view.superview?.subviews.forEach { sib in
                if sib !== view, sib.appearsDecorative {
                    sib.isUserInteractionEnabled = false
                }
            }
        }
        // 3) Content shape hint (SwiftUI) – best effort: mark via accessibility to cue your View modifier layer
        if missingShape {
            view.accessibilityHint = (view.accessibilityHint ?? "") + " [needsContentShape]"
        }
    }
}

// MARK: UIView helpers

private extension UIView {
    var isActuallyHittable: Bool {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return false }
        var v: UIView? = self
        while let cur = v {
            if cur.isHidden || cur.alpha <= 0.01 || !cur.isUserInteractionEnabled { return false }
            v = cur.superview
        }
        return true
    }

    var windowFrame: CGRect {
        guard let w = window else { return .zero }
        return convert(bounds, to: w)
    }

    // Heuristic: UIButton/UIControl, cells, SwiftUI hosting button containers
    var isIntendedTappable: Bool {
        if self is UIControl { return true }
        if String(describing: type(of: self)).contains("Button") { return true }
        if String(describing: type(of: self)).contains("NavigationLink") { return true }
        if accessibilityTraits.contains(.button) { return true }
        return false
    }

    var appearsDecorative: Bool {
        // Obvious visuals: UIVisualEffectView, image/gradient containers, non-accessible views
        if self is UIVisualEffectView { return true }
        if accessibilityTraits.isEmpty && accessibilityLabel == nil && subviews.count > 0 && !(self is UIControl) {
            // treat as decorative unless it contains a control
            let containsControl = TapDoctor.flatten(self).contains { $0 is UIControl }
            return !containsControl
        }
        return false
    }

    var isSwiftUIButton: Bool {
        String(describing: type(of: self)).contains("Button")
    }

    var hasContentShape: Bool {
        // Not directly discoverable; use accessibilityHint breadcrumb from your SwiftUI modifier.
        accessibilityHint?.contains("[hasContentShape]") == true
    }

    @objc func _td_passthroughTap() {
        // Bubble to nearest control
        var v: UIView? = self
        while let cur = v {
            if let c = cur as? UIControl {
                c.sendActions(for: .touchUpInside)
                break
            }
            v = cur.superview
        }
    }
}

// MARK: On-screen highlight

final class TDOverlay: UIView {
    var reason: String = ""
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: 8)
        path.setLineDash([6, 4], count: 2, phase: 0)
        path.lineWidth = 2
        UIColor.systemRed.setStroke()
        path.stroke()

        let label = UILabel()
        label.text = reason
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .systemRed
        label.sizeToFit()
        label.frame.origin = CGPoint(x: 4, y: 4)
        addSubview(label)
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
}

// MARK: SwiftUI Integration

struct TapDoctorDecorativeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.async {
                    if let hostingController = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .flatMap({ $0.windows })
                        .first(where: { $0.isKeyWindow })?
                        .rootViewController {
                        markDecorativeViews(in: hostingController.view)
                    }
                }
            }
    }
    
    private func markDecorativeViews(in view: UIView) {
        view.accessibilityHint = (view.accessibilityHint ?? "") + " [decorative]"
        view.subviews.forEach { markDecorativeViews(in: $0) }
    }
}

struct TapDoctorContentShapeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onAppear {
                DispatchQueue.main.async {
                    if let hostingController = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .flatMap({ $0.windows })
                        .first(where: { $0.isKeyWindow })?
                        .rootViewController {
                        markContentShapeViews(in: hostingController.view)
                    }
                }
            }
    }
    
    private func markContentShapeViews(in view: UIView) {
        view.accessibilityHint = (view.accessibilityHint ?? "") + " [hasContentShape]"
        view.subviews.forEach { markContentShapeViews(in: $0) }
    }
}

extension View {
    func decorative() -> some View {
        modifier(TapDoctorDecorativeModifier())
    }
    
    func tapDoctorContentShape() -> some View {
        modifier(TapDoctorContentShapeModifier())
    }
}