import SwiftUI
import MapKit
import CoreLocation

struct RouteMapView: View {
    let coords: [CLLocationCoordinate2D]
    @State private var region: MKCoordinateRegion = MKCoordinateRegion()
    
    var body: some View {
        if #available(iOS 17.0, *) {
            Map(initialPosition: .region(region), interactionModes: [.zoom, .pan, .rotate]) {
                if !coords.isEmpty {
                    let poly = MKPolyline(coordinates: coords, count: coords.count)
                    MapPolyline(poly)
                        .stroke(.white, lineWidth: 4)
                } else {
                    // Debug: Show when coords are empty
                    MapCircle(center: CLLocationCoordinate2D(latitude: 40.6461, longitude: -111.4980), radius: 1000)
                        .foregroundStyle(.red.opacity(0.3))
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .onAppear {
                if !coords.isEmpty {
                    region = RouteMapHelpers.region(fitting: coords)
                } else {
                    // Debug: Set default region when coords are empty
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 40.6461, longitude: -111.4980),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
                print("RouteMapView: coords.count = \(coords.count)")
            }
        } else {
            // Fallback for iOS 16 and below
            MapViewRepresentable(coords: coords, region: $region)
                .onAppear {
                    if !coords.isEmpty {
                        region = RouteMapHelpers.region(fitting: coords)
                    }
                }
        }
    }
}

@available(iOS 16.0, *)
struct MapViewRepresentable: UIViewRepresentable {
    let coords: [CLLocationCoordinate2D]
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .standard
        mapView.isUserInteractionEnabled = true
        mapView.isZoomEnabled = true
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = true
        mapView.isScrollEnabled = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        if !coords.isEmpty {
            uiView.setRegion(region, animated: true)
            
            // Remove existing overlays
            uiView.removeOverlays(uiView.overlays)
            
            // Add polyline
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            uiView.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .white
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}