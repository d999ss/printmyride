import Foundation
import CoreGraphics
import os.log

/// High-performance point simplification with parallel processing
struct OptimizedSimplify {
    private static let logger = Logger(subsystem: "PMR", category: "Simplify")
    
    // MARK: - Parallel RDP Implementation
    
    /// Parallel Ramer-Douglas-Peucker simplification using TaskGroup
    static func parallelRDP(_ points: [CGPoint], epsilon: Double, minChunkSize: Int = 500) async -> [CGPoint] {
        guard points.count > minChunkSize * 2 else {
            return rdp(points, epsilon: epsilon)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let processorCount = ProcessInfo.processInfo.activeProcessorCount
        let chunkSize = max(minChunkSize, points.count / processorCount)
        
        Self.logger.info("Starting parallel RDP: \(points.count) points, \(processorCount) cores")
        
        // Create overlapping chunks to preserve connectivity
        let chunks = createOverlappingChunks(points, chunkSize: chunkSize, overlap: 50)
        
        let simplifiedChunks = await withTaskGroup(of: (Int, [CGPoint]).self) { group in
            for (index, chunk) in chunks.enumerated() {
                group.addTask(priority: .high) {
                    let simplified = rdp(chunk, epsilon: epsilon)
                    return (index, simplified)
                }
            }
            
            var results: [(Int, [CGPoint])] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map { $1 }
        }
        
        // Merge chunks and remove overlap duplicates
        let merged = mergeChunks(simplifiedChunks, originalOverlap: 50)
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        Self.logger.info("Parallel RDP completed: \(points.count) → \(merged.count) points (\(String(format: "%.1f", duration))ms)")
        
        return merged
    }
    
    // MARK: - Smart Budget with Priority Preservation
    
    /// Memory-efficient budget allocation with endpoint preservation
    static func smartBudget(_ points: [CGPoint], maxPoints: Int, preserveEnds: Bool = true, preserveCurvature: Bool = true) -> [CGPoint] {
        guard points.count > maxPoints else { return points }
        
        if maxPoints < 3 { return Array(points.prefix(maxPoints)) }
        
        var result: [CGPoint] = []
        
        if preserveCurvature {
            // Calculate curvature importance for each point
            let importance = calculateImportance(points)
            let importantIndices = selectImportantPoints(importance, count: maxPoints)
            result = importantIndices.map { points[$0] }
        } else if preserveEnds {
            // Simple uniform sampling with endpoint preservation
            result.append(points.first!)
            let step = Float(points.count - 2) / Float(maxPoints - 2)
            
            for i in 1..<(maxPoints - 1) {
                let index = Int(Float(i) * step) + 1
                result.append(points[index])
            }
            result.append(points.last!)
        } else {
            // Pure uniform sampling
            let step = Float(points.count) / Float(maxPoints)
            for i in 0..<maxPoints {
                let index = Int(Float(i) * step)
                result.append(points[index])
            }
        }
        
        return result
    }
    
    // MARK: - Advanced Simplification with Curvature Analysis
    
    /// Adaptive simplification based on route complexity
    static func adaptiveSimplify(_ points: [CGPoint], targetPoints: Int, preserveDetail: Bool = true) async -> [CGPoint] {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Analyze route complexity
        let complexity = analyzeComplexity(points)
        
        // Choose strategy based on complexity
        var simplified: [CGPoint]
        
        if complexity.highDetail && preserveDetail {
            // Use parallel RDP for complex routes
            let epsilon = calculateAdaptiveEpsilon(points, targetPoints: targetPoints)
            simplified = await parallelRDP(points, epsilon: epsilon)
        } else {
            // Use smart budget for simple routes
            simplified = smartBudget(points, maxPoints: targetPoints, preserveCurvature: true)
        }
        
        let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        Self.logger.info("Adaptive simplify: \(points.count) → \(simplified.count) points (\(String(format: "%.1f", duration))ms)")
        
        return simplified
    }
    
    // MARK: - Private Helpers
    
    private static func createOverlappingChunks(_ points: [CGPoint], chunkSize: Int, overlap: Int) -> [[CGPoint]] {
        var chunks: [[CGPoint]] = []
        var start = 0
        
        while start < points.count {
            let end = min(start + chunkSize, points.count)
            let chunk = Array(points[start..<end])
            chunks.append(chunk)
            start = end - overlap
            
            if start >= points.count - overlap {
                break
            }
        }
        
        return chunks
    }
    
    private static func mergeChunks(_ chunks: [[CGPoint]], originalOverlap: Int) -> [CGPoint] {
        guard !chunks.isEmpty else { return [] }
        
        var merged = chunks[0]
        
        for i in 1..<chunks.count {
            let chunk = chunks[i]
            // Remove overlap points from beginning of chunk
            let startIndex = min(originalOverlap, chunk.count - 1)
            merged.append(contentsOf: chunk.dropFirst(startIndex))
        }
        
        return merged
    }
    
    private static func calculateImportance(_ points: [CGPoint]) -> [Double] {
        guard points.count > 2 else { return Array(repeating: 1.0, count: points.count) }
        
        var importance: [Double] = [1.0] // First point always important
        
        for i in 1..<(points.count - 1) {
            let prev = points[i - 1]
            let curr = points[i]
            let next = points[i + 1]
            
            // Calculate curvature using angle between vectors
            let v1 = CGVector(dx: curr.x - prev.x, dy: curr.y - prev.y)
            let v2 = CGVector(dx: next.x - curr.x, dy: next.y - curr.y)
            
            let angle = abs(atan2(v1.dx * v2.dy - v1.dy * v2.dx, v1.dx * v2.dx + v1.dy * v2.dy))
            importance.append(angle)
        }
        
        importance.append(1.0) // Last point always important
        return importance
    }
    
    private static func selectImportantPoints(_ importance: [Double], count: Int) -> [Int] {
        let indexed = importance.enumerated().sorted { $0.element > $1.element }
        return indexed.prefix(count).map { $0.offset }.sorted()
    }
    
    private struct RouteComplexity {
        let highDetail: Bool
        let averageCurvature: Double
        let maxCurvature: Double
    }
    
    private static func analyzeComplexity(_ points: [CGPoint]) -> RouteComplexity {
        let importance = calculateImportance(points)
        let avgCurvature = importance.reduce(0, +) / Double(importance.count)
        let maxCurvature = importance.max() ?? 0
        
        return RouteComplexity(
            highDetail: avgCurvature > 0.5 || maxCurvature > 1.0,
            averageCurvature: avgCurvature,
            maxCurvature: maxCurvature
        )
    }
    
    private static func calculateAdaptiveEpsilon(_ points: [CGPoint], targetPoints: Int) -> Double {
        // Calculate bounding box diagonal
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let width = xs.max()! - xs.min()!
        let height = ys.max()! - ys.min()!
        let diagonal = sqrt(width * width + height * height)
        
        // Adaptive epsilon based on target reduction ratio
        let reductionRatio = Double(targetPoints) / Double(points.count)
        let baseEpsilon = diagonal * 0.001
        
        return baseEpsilon / max(reductionRatio, 0.1)
    }
    
    // MARK: - Legacy RDP for Comparison
    
    static func rdp(_ points: [CGPoint], epsilon: Double) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        let first = points.first!
        let last = points.last!
        
        var maxDistance: Double = 0
        var maxIndex = 0
        
        for i in 1..<(points.count - 1) {
            let distance = perpendicularDistance(points[i], lineStart: first, lineEnd: last)
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        if maxDistance > epsilon {
            let left = rdp(Array(points[0...maxIndex]), epsilon: epsilon)
            let right = rdp(Array(points[maxIndex..<points.count]), epsilon: epsilon)
            return left + right.dropFirst()
        } else {
            return [first, last]
        }
    }
    
    private static func perpendicularDistance(_ point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> Double {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        
        if dx == 0 && dy == 0 {
            return sqrt(pow(point.x - lineStart.x, 2) + pow(point.y - lineStart.y, 2))
        }
        
        let t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (dx * dx + dy * dy)
        let clampedT = max(0, min(1, t))
        
        let projX = lineStart.x + clampedT * dx
        let projY = lineStart.y + clampedT * dy
        
        return sqrt(pow(point.x - projX, 2) + pow(point.y - projY, 2))
    }
}