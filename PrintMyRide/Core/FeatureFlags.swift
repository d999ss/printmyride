import Foundation

/// Feature flags for safe refactoring
/// Toggle these to gradually roll out simplified code paths
struct FeatureFlags {
    
    // MARK: - Poster Generation
    /// Use simplified poster renderer (removes multiple implementations)
    static let useSimplifiedPosterRenderer = false
    
    /// Skip test poster generation workarounds
    static let skipTestPosterWorkarounds = false
    
    // MARK: - Authentication
    /// Use unified auth system (removes duplicate auth paths)
    static let useUnifiedAuth = false
    
    /// Skip demo/preview auth flows
    static let requireRealAuth = false
    
    // MARK: - Data Layer
    /// Use simplified storage (removes redundant caching)
    static let useSimplifiedStorage = false
    
    /// Remove sample/mock data generators
    static let disableMockData = false
    
    // MARK: - UI Components
    /// Use simplified poster designs (reduce from 10+ to 3 core designs)
    static let useCorePosterDesigns = false
    
    /// Remove placeholder/demo views
    static let hidePlaceholderViews = false
    
    // MARK: - Debug & Development
    /// Enable verbose logging for refactored code paths
    static let logRefactoredPaths = true
    
    /// Enable metrics collection
    static let collectUsageMetrics = true
    
    // MARK: - Rollback
    /// Emergency switch to revert all changes
    static let useOriginalImplementation = false
    
    // MARK: - Helper Methods
    
    static func shouldUseNewPosterFlow() -> Bool {
        return !useOriginalImplementation && useSimplifiedPosterRenderer
    }
    
    static func shouldUseNewAuthFlow() -> Bool {
        return !useOriginalImplementation && useUnifiedAuth
    }
    
    static func log(_ message: String, path: String = #function) {
        guard logRefactoredPaths else { return }
        print("[FeatureFlag] \(path): \(message)")
    }
}

// MARK: - Version Control
extension FeatureFlags {
    /// Track which version introduced each refactor
    static let refactorVersion = "0.3.0"
    
    /// Date when refactoring started
    static let refactorStartDate = Date()
    
    /// Minimum iOS version for new code paths
    static let minimumOSForRefactor = "16.0"
}