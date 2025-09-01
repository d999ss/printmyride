import Foundation

@MainActor
final class AddressStore: ObservableObject {
    @Published var address = ShippingAddress()
    private let fileName = "shipping_address.json"

    init() { load() }

    func load() {
        let url = urlForFile()
        guard let data = try? Data(contentsOf: url) else { return }
        if let decoded = try? JSONDecoder().decode(ShippingAddress.self, from: data) {
            address = decoded
        }
    }

    func save() {
        let url = urlForFile()
        if let data = try? JSONEncoder().encode(address) {
            try? data.write(to: url, options: [.atomic])
        }
    }

    private func urlForFile() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(fileName)
    }
}