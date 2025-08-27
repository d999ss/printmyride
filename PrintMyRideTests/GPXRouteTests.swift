import XCTest
@testable import PrintMyRide

final class GPXRouteTests: XCTestCase {
    
    // MARK: - GPX Point Tests
    
    func testGPXPointInitialization() {
        let point = GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: 10.0, t: Date())
        
        XCTAssertEqual(point.lat, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(point.lon, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(point.ele, 10.0)
        XCTAssertNotNil(point.t)
    }
    
    func testGPXPointCoordinateConversion() {
        let point = GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil)
        let coordinate = point.coordinate
        
        XCTAssertEqual(coordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, -122.4194, accuracy: 0.0001)
    }
    
    // MARK: - GPX Route Tests
    
    func testGPXRouteInitialization() {
        let points = [
            GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil),
            GPXRoute.Point(lat: 37.7849, lon: -122.4094, ele: nil, t: nil)
        ]
        
        let route = GPXRoute(points: points, distanceMeters: 1609.34, duration: 3600)
        
        XCTAssertEqual(route.points.count, 2)
        XCTAssertEqual(route.distanceMeters, 1609.34, accuracy: 0.01)
        XCTAssertEqual(route.duration, 3600)
        XCTAssertNotNil(route.id)
    }
    
    func testGPXRouteDistanceCalculation() {
        let points = [
            GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil), // San Francisco
            GPXRoute.Point(lat: 37.7849, lon: -122.4094, ele: nil, t: nil)  // ~1 mile north
        ]
        
        let route = GPXRoute(points: points, distanceMeters: 1609.34, duration: nil)
        
        // Distance should be approximately 1 mile (1609.34 meters)
        XCTAssertEqual(route.distanceMeters, 1609.34, accuracy: 0.01)
        XCTAssertEqual(route.distanceInMiles, 1.0, accuracy: 0.001)
        XCTAssertEqual(route.distanceInKilometers, 1.6, accuracy: 0.001)
    }
    
    func testGPXRouteDurationCalculation() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(3600) // 1 hour later
        
        let points = [
            GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: startTime),
            GPXRoute.Point(lat: 37.7849, lon: -122.4094, ele: nil, t: endTime)
        ]
        
        let route = GPXRoute(points: points, distanceMeters: 1609.34, duration: 3600)
        
        XCTAssertEqual(route.duration, 3600, accuracy: 1.0)
        XCTAssertEqual(route.durationInHours, 1.0, accuracy: 0.001)
        XCTAssertEqual(route.durationInMinutes, 60.0, accuracy: 0.1)
    }
    
    func testGPXRouteSpeedCalculation() {
        let points = [
            GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil),
            GPXRoute.Point(lat: 37.7849, lon: -122.4094, ele: nil, t: nil)
        ]
        
        let route = GPXRoute(points: points, distanceMeters: 1609.34, duration: 3600)
        
        // Speed should be approximately 1 mph (0.447 m/s)
        XCTAssertEqual(route.averageSpeed, 0.447, accuracy: 0.001)
        XCTAssertEqual(route.averageSpeedMPH, 1.0, accuracy: 0.001)
        XCTAssertEqual(route.averageSpeedKPH, 1.6, accuracy: 0.001)
    }
    
    func testGPXRouteBoundingBox() {
        let points = [
            GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil),
            GPXRoute.Point(lat: 37.7849, lon: -122.4094, ele: nil, t: nil),
            GPXRoute.Point(lat: 37.7949, lon: -122.3994, ele: nil, t: nil)
        ]
        
        let route = GPXRoute(points: points, distanceMeters: 2400.0, duration: nil)
        let bbox = route.boundingBox
        
        XCTAssertEqual(bbox.minLat, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(bbox.maxLat, 37.7949, accuracy: 0.0001)
        XCTAssertEqual(bbox.minLon, -122.4194, accuracy: 0.0001)
        XCTAssertEqual(bbox.maxLon, -122.3994, accuracy: 0.0001)
    }
    
    func testGPXRouteCenterCoordinate() {
        let points = [
            GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil),
            GPXRoute.Point(lat: 37.7849, lon: -122.4094, ele: nil, t: nil)
        ]
        
        let route = GPXRoute(points: points, distanceMeters: 1609.34, duration: nil)
        let center = route.centerCoordinate
        
        let expectedLat = (37.7749 + 37.7849) / 2
        let expectedLon = (-122.4194 + -122.4094) / 2
        
        XCTAssertEqual(center.latitude, expectedLat, accuracy: 0.0001)
        XCTAssertEqual(center.longitude, expectedLon, accuracy: 0.0001)
    }
    
    // MARK: - Edge Cases
    
    func testEmptyRoute() {
        let route = GPXRoute(points: [], distanceMeters: 0, duration: nil)
        
        XCTAssertEqual(route.distanceMeters, 0)
        XCTAssertEqual(route.distanceInMiles, 0)
        XCTAssertEqual(route.distanceInKilometers, 0)
        XCTAssertNil(route.duration)
        XCTAssertEqual(route.averageSpeed, 0)
    }
    
    func testSinglePointRoute() {
        let points = [GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil)]
        let route = GPXRoute(points: points, distanceMeters: 0, duration: nil)
        
        XCTAssertEqual(route.distanceMeters, 0)
        XCTAssertEqual(route.distanceInMiles, 0)
        XCTAssertEqual(route.distanceInKilometers, 0)
    }
    
    func testRouteWithNoTimestamps() {
        let points = [
            GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil),
            GPXRoute.Point(lat: 37.7849, lon: -122.4094, ele: nil, t: nil)
        ]
        
        let route = GPXRoute(points: points, distanceMeters: 1609.34, duration: nil)
        
        XCTAssertNil(route.duration)
        XCTAssertEqual(route.averageSpeed, 0)
    }
    
    // MARK: - Haversine Distance Tests
    
    func testHaversineDistanceAccuracy() {
        // Test with known distances
        let point1 = GPXRoute.Point(lat: 0.0, lon: 0.0, ele: nil, t: nil)
        let point2 = GPXRoute.Point(lat: 0.0, lon: 1.0, ele: nil, t: nil)
        
        // 1 degree of longitude at equator is approximately 111.32 km
        let expectedDistance = 111320.0 // meters
        let actualDistance = calculateHaversineDistance(from: point1, to: point2)
        
        XCTAssertEqual(actualDistance, expectedDistance, accuracy: 1000.0) // Allow 1km tolerance
    }
    
    func testHaversineDistanceSymmetry() {
        let point1 = GPXRoute.Point(lat: 37.7749, lon: -122.4194, ele: nil, t: nil)
        let point2 = GPXRoute.Point(lat: 37.7849, lon: -122.4094, ele: nil, t: nil)
        
        let distance1to2 = calculateHaversineDistance(from: point1, to: point2)
        let distance2to1 = calculateHaversineDistance(from: point2, to: point1)
        
        XCTAssertEqual(distance1to2, distance2to1, accuracy: 0.1)
    }
    
    // MARK: - Helper Methods
    
    private func calculateHaversineDistance(from point1: GPXRoute.Point, to point2: GPXRoute.Point) -> Double {
        let earthRadius = 6371000.0 // Earth's radius in meters
        
        let lat1Rad = point1.lat * .pi / 180
        let lat2Rad = point2.lat * .pi / 180
        let deltaLatRad = (point2.lat - point1.lat) * .pi / 180
        let deltaLonRad = (point2.lon - point1.lon) * .pi / 180
        
        let a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLonRad / 2) * sin(deltaLonRad / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}
