import XCTest

final class LinkCheckerTests: XCTestCase {
    func testAllLinksReachable() async {
        let data = try! Data(contentsOf: Bundle(for: Self.self).url(forResource: "Links", withExtension: "json", subdirectory: "Fixtures")!)
        let json = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        let links = (json["links"] as? [String]) ?? []

        for urlString in links {
            if urlString.hasPrefix("mailto:") { continue } // skip non-http(s)
            guard let url = URL(string: urlString) else {
                XCTFail("Bad URL: \(urlString)"); continue
            }
            let ok = await headOK(url)
            XCTAssertTrue(ok, "Dead link: \(url)")
        }
    }

    private func headOK(_ url: URL) async -> Bool {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        req.timeoutInterval = 8
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else { return false }
            return (200...399).contains(http.statusCode)
        } catch { return false }
    }
}