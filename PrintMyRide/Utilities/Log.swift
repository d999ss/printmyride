import OSLog

enum PMRLog {
    static let general = Logger(subsystem: "com.printmyride", category: "general")
    static let ui      = Logger(subsystem: "com.printmyride", category: "ui")
    static let maps    = Logger(subsystem: "com.printmyride", category: "maps")
    static let export  = Logger(subsystem: "com.printmyride", category: "export")
    static let paywall = Logger(subsystem: "com.printmyride", category: "paywall")
}

@MainActor
final class ErrorBus: ObservableObject {
    static let shared = ErrorBus()
    @Published var lastMessage: String?
    func report(_ message: String) {
        lastMessage = message
        PMRLog.general.error("\(message, privacy: .public)")
    }
}