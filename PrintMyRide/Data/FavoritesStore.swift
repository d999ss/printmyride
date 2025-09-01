import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    static let shared = FavoritesStore()
    @Published private(set) var ids: Set<UUID> = []
    private let key = "pmr.favorites"
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let arr = try? JSONDecoder().decode([UUID].self, from: data) {
            ids = Set(arr)
        }
    }
    func toggle(_ id: UUID) { 
        if ids.contains(id) { 
            ids.remove(id) 
        } else { 
            ids.insert(id) 
        }
        persist() 
    }
    func contains(_ id: UUID) -> Bool { ids.contains(id) }
    private func persist() {
        if let data = try? JSONEncoder().encode(Array(ids)) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}