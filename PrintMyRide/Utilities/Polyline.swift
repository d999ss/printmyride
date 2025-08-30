import CoreLocation

func decodePolyline(_ polyline: String) -> [CLLocationCoordinate2D] {
    var coords: [CLLocationCoordinate2D] = []
    let bytes = Array(polyline.utf8)
    var idx = 0, lat = 0, lon = 0
    
    while idx < bytes.count {
        var b: Int, shift = 0, result = 0
        repeat { 
            b = Int(bytes[idx]) - 63
            idx += 1
            result |= (b & 0x1f) << shift
            shift += 5 
        } while b >= 0x20
        
        let dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
        lat += dlat
        
        shift = 0; result = 0
        repeat { 
            b = Int(bytes[idx]) - 63
            idx += 1
            result |= (b & 0x1f) << shift
            shift += 5 
        } while b >= 0x20
        
        let dlon = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
        lon += dlon
        
        coords.append(.init(latitude: Double(lat) / 1e5, longitude: Double(lon) / 1e5))
    }
    
    return coords
}