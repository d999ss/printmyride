import Foundation

struct Order: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let status: String   // "pending" | "shipped" | ...
}

protocol OrderService {
    func listOrders() async throws -> [Order]
}

final class LocalOrderService: OrderService {
    func listOrders() async throws -> [Order] { [] } // no orders in V1
}