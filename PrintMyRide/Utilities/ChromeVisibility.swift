import SwiftUI

final class ChromeVisibility: ObservableObject {
    @Published var visible = true
    private var timer: Timer?
    
    func showTemporarily(_ seconds: TimeInterval = 2.0) {
        visible = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                self?.visible = false
            }
        }
    }
    
    func show() {
        withAnimation(.easeInOut(duration: 0.2)) {
            visible = true
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}