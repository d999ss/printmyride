import CoreLocation

extension GPXRoute {
    /// Canonical access: flatten whatever storage we have into clean coordinates.
    var coordinates: [CLLocationCoordinate2D] {
        // Case B: stored as custom points with lat/lon Doubles (our current model)
        return points.map { $0.coordinate }
    }
    
    var elevations: [Double] { 
        return points.compactMap { $0.ele }
    }
    
    var timestamps: [Date] { 
        return points.compactMap { $0.t }
    }
}