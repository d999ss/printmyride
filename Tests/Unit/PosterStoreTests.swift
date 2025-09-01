import XCTest
@testable import PrintMyRide

final class PosterStoreTests: XCTestCase {
    @MainActor
    func testSeedingRunsOnce() async {
        let store = PosterStore()
        UserDefaults.standard.removeObject(forKey: "pmr.hasSeededSamplePoster")
        await store.bootstrap() // with asset present this seeds; asset absence should no-op
        let firstCount = store.posters.count
        await store.bootstrap()
        XCTAssertEqual(firstCount, store.posters.count, "Seeding should run once")
    }
}