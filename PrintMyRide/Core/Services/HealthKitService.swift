import Foundation
import HealthKit
import CoreLocation

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAuthorization() async throws {
        let workoutType = HKObjectType.workoutType()
        let routeType = HKSeriesType.workoutRoute()
        
        try await healthStore.requestAuthorization(
            toShare: [],
            read: [workoutType, routeType]
        )
    }
    
    func fetchCyclingWorkouts(limit: Int = 10) async throws -> [Ride] {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .cycling)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = samples as? [HKWorkout] ?? []
                Task {
                    let rides = await self.convertWorkoutsToRides(workouts)
                    continuation.resume(returning: rides)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    private func convertWorkoutsToRides(_ workouts: [HKWorkout]) async -> [Ride] {
        var rides: [Ride] = []
        
        for workout in workouts {
            let coordinates = await fetchRouteData(for: workout)
            
            let ride = Ride(
                id: UUID(),
                title: formatWorkoutTitle(workout),
                distanceKm: (workout.totalDistance?.doubleValue(for: .meter()) ?? 0) / 1000.0,
                elevationGainM: (workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) * 0.1, // Rough estimate
                duration: workout.duration,
                coordinates: coordinates,
                date: workout.startDate
            )
            
            rides.append(ride)
        }
        
        return rides
    }
    
    private func fetchRouteData(for workout: HKWorkout) async -> [CLLocationCoordinate2D] {
        let routeType = HKSeriesType.workoutRoute()
        
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let route = samples?.first as? HKWorkoutRoute else {
                    continuation.resume(returning: [])
                    return
                }
                
                var coordinates: [CLLocationCoordinate2D] = []
                let routeQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, _ in
                    if let locations = locations {
                        coordinates.append(contentsOf: locations.map { $0.coordinate })
                    }
                    
                    if done {
                        continuation.resume(returning: coordinates)
                    }
                }
                
                self.healthStore.execute(routeQuery)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func formatWorkoutTitle(_ workout: HKWorkout) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Ride \(formatter.string(from: workout.startDate))"
    }
}