import XCTest
import SnapshotTesting
@testable import PrintMyRide
import SwiftUI

final class GallerySnapshotTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        isRecording = false // flip to true to update golden snapshots
    }

    func testGalleryLight() {
        let vc = UIHostingController(rootView: NavigationStack { GalleryView() })
        assertSnapshot(of: vc, as: .image(on: .iPhone13))
    }
}