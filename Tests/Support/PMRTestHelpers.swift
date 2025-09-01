import Foundation
import XCTest

enum PMRFixtures {
    static var bundle: Bundle { Bundle(for: Dummy.self) }
    private final class Dummy: XCTestCase {}

    static func data(named name: String) -> Data {
        let parts = name.split(separator: ".")
        let file = parts.first.map(String.init) ?? name
        let ext  = parts.count > 1 ? String(parts.last!) : nil
        guard let url = bundle.url(forResource: file, withExtension: ext) else {
            fatalError("Missing fixture \(name)")
        }
        return (try? Data(contentsOf: url)) ?? Data()
    }
}