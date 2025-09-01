import SwiftUI
import Foundation
import CoreLocation

/// Comprehensive poster render performance benchmark
struct PosterBenchmark {
    static func run() async {
        print("🚀 Starting PrintMyRide Poster Render Benchmark")
        print("=" * 50)
        
        // Test data
        let testCoords = SampleRouteFactory.demoRoute().coordinates
        let testSizes = [
            CGSize(width: 300, height: 400),   // Thumbnail
            CGSize(width: 800, height: 1000),  // Medium
            CGSize(width: 1600, height: 2000)  // High-res
        ]
        
        for size in testSizes {
            await benchmarkPosterRender(coords: testCoords, size: size)
        }
        
        print("\n✅ Benchmark Complete")
    }
    
    private static func benchmarkPosterRender(coords: [CLLocationCoordinate2D], size: CGSize) async {
        let sizeLabel = "\(Int(size.width))x\(Int(size.height))"
        print("\n📊 Benchmarking \(sizeLabel)")
        
        // 1. Route Canvas Rendering
        let canvasStart = CFAbsoluteTimeGetCurrent()
        let design = PosterDesignStub.classic()
        let route = GPXRoute(coordinates: coords, elevations: [], timestamps: [])
        
        // Simulate canvas render (point simplification)
        let viewDiag = hypot(size.width, size.height)
        var pts = coords.map { c in
            CGPoint(x: c.longitude, y: c.latitude)
        }
        let preSimpCount = pts.count
        pts = Simplify.rdp(pts, epsilon: viewDiag * 0.001)
        pts = Simplify.budget(pts, maxPoints: 4000)
        let postSimpCount = pts.count
        
        let canvasTime = CFAbsoluteTimeGetCurrent() - canvasStart
        
        // 2. Map Snapshot Generation
        let snapStart = CFAbsoluteTimeGetCurrent()
        let mapImage = await MapSnapshotService.snapshot(coords: coords, size: size)
        let snapTime = CFAbsoluteTimeGetCurrent() - snapStart
        
        // 3. Export Simulation
        let exportStart = CFAbsoluteTimeGetCurrent()
        _ = await PosterExport.pngAsync(design: design, route: route, dpi: 300, bleedInches: 0.125, includeGrid: false)
        let exportTime = CFAbsoluteTimeGetCurrent() - exportStart
        
        // Results
        print("  📐 Size: \(sizeLabel)")
        print("  🎯 Points: \(preSimpCount) → \(postSimpCount) (\((Float(postSimpCount)/Float(preSimpCount) * 100).rounded())%)")
        print("  🖼️  Canvas: \((canvasTime * 1000).rounded())ms")
        print("  🗺️  Snapshot: \((snapTime * 1000).rounded())ms \(mapImage != nil ? "✅" : "❌")")
        print("  📤 Export: \((exportTime * 1000).rounded())ms")
        print("  ⚡ Total: \(((canvasTime + snapTime + exportTime) * 1000).rounded())ms")
    }
}