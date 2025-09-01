import XCTest
import CryptoKit
@testable import PrintMyRide
import CoreLocation
import UIKit

final class PosterPDFGoldenTests: XCTestCase {
    @MainActor
    func testPosterPDFDeterminism() async throws {
        // Fixed coords rectangle
        let coords = [
            CLLocationCoordinate2D(latitude: 40.0, longitude: -111.5),
            CLLocationCoordinate2D(latitude: 40.1, longitude: -111.5),
            CLLocationCoordinate2D(latitude: 40.1, longitude: -111.4),
            CLLocationCoordinate2D(latitude: 40.0, longitude: -111.4)
        ]
        
        // Use existing RouteRenderer to create deterministic poster
        guard let posterImage = await RouteRenderer.renderPoster(
            coordinates: coords,
            title: "Golden Ride",
            distance: "10.0 km",
            duration: "30m",
            date: "Jan 1, 2024",
            size: CGSize(width: 18*300, height: 24*300), // 18x24 at 300 DPI
            style: .standard
        ) else {
            XCTFail("Failed to render poster")
            return
        }
        
        // Export as PDF
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("golden.pdf")
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: posterImage.size), nil)
        UIGraphicsBeginPDFPage()
        posterImage.draw(in: CGRect(origin: .zero, size: posterImage.size))
        UIGraphicsEndPDFContext()
        try pdfData.write(to: tmp)
        
        let data = try Data(contentsOf: tmp)
        let digest = SHA256.hash(data: data)
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        
        // For first run, print the hash to set as golden
        print("PDF Hash: \(hash)")
        
        // Replace below once you accept a golden file
        let goldenHash = "a1b2c3d4e5f6789012345678901234567890abcdef12345678901234567890abcd"
        if goldenHash == "PLACEHOLDER_HASH" {
            print("Set golden hash to: \(hash)")
            // For first run, don't fail - just print the hash
        } else {
            XCTAssertEqual(hash, goldenHash, "PDF output drifted.\nExpected: \(goldenHash)\nGot: \(hash)")
        }
    }
}