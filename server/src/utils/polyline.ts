import polyline from '@mapbox/polyline';

export interface Coordinate {
    latitude: number;
    longitude: number;
    elevation?: number;
    time?: Date;
}

export function decodePolyline(encoded: string): Coordinate[] {
    try {
        const decoded = polyline.decode(encoded);
        return decoded.map(([lat, lng]) => ({
            latitude: lat,
            longitude: lng
        }));
    } catch (error) {
        console.error('❌ Failed to decode polyline:', error);
        return [];
    }
}

export function generateGPX(coordinates: Coordinate[], name: string, metadata?: {
    distance?: number;
    movingTime?: number;
    elevationGain?: number;
    type?: string;
    startTime?: string;
}): string {
    const gpxHeader = `<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="PrintMyRide" xmlns="http://www.topografix.com/GPX/1/1">
    <metadata>
        <name>${escapeXml(name)}</name>
        <desc>Exported from PrintMyRide via Strava</desc>
        <time>${new Date().toISOString()}</time>
    </metadata>`;
    
    const trackStart = `    <trk>
        <name>${escapeXml(name)}</name>
        <type>${escapeXml(metadata?.type || 'Ride')}</type>
        <trkseg>`;
    
    const trackPoints = coordinates.map(coord => {
        let point = `            <trkpt lat="${coord.latitude}" lon="${coord.longitude}">`;
        
        if (coord.elevation !== undefined) {
            point += `\n                <ele>${coord.elevation}</ele>`;
        }
        
        if (coord.time) {
            point += `\n                <time>${coord.time.toISOString()}</time>`;
        }
        
        point += '\n            </trkpt>';
        return point;
    }).join('\n');
    
    const trackEnd = `        </trkseg>
    </trk>`;
    
    const gpxFooter = '</gpx>';
    
    return [gpxHeader, trackStart, trackPoints, trackEnd, gpxFooter].join('\n');
}

function escapeXml(unsafe: string): string {
    return unsafe.replace(/[<>&'"]/g, (c) => {
        switch (c) {
            case '<': return '&lt;';
            case '>': return '&gt;';
            case '&': return '&amp;';
            case "'": return '&apos;';
            case '"': return '&quot;';
            default: return c;
        }
    });
}

export function calculateDistance(coordinates: Coordinate[]): number {
    if (coordinates.length < 2) return 0;
    
    let totalDistance = 0;
    
    for (let i = 1; i < coordinates.length; i++) {
        const dist = haversineDistance(
            coordinates[i-1].latitude, coordinates[i-1].longitude,
            coordinates[i].latitude, coordinates[i].longitude
        );
        totalDistance += dist;
    }
    
    return totalDistance;
}

function haversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371000; // Earth's radius in meters
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;
    
    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    
    return R * c;
}