//
// Copyright © 2018 Janko Luin. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation

class GeofencingController: NSObject {
    static var current: GeofencingController!

    var managedObjectContext: NSManagedObjectContext
    var locationManager: CLLocationManager
    var pendingLocations: [Location] = []

    init(managedObjectContext: NSManagedObjectContext) {
        locationManager = CLLocationManager()
        self.managedObjectContext = managedObjectContext
        super.init()

        locationManager.delegate = self
    }

    func startup() {
        locationManager.startMonitoringSignificantLocationChanges()
    }

    func add(location: Location) {
        locationManager.requestAlwaysAuthorization()

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            startMonitoring(location: location)
        case .notDetermined:
            pendingLocations.append(location)
        case .denied, .restricted:
            NSLog("App is not allowed to monitor locations.")
        }
    }

    fileprivate func startMonitoring(location: Location) {
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            // Register the region.
            let region = CLCircularRegion(center: location.coordinate,
                                          radius: location.radiusInMeters,
                                          identifier: location.title ?? "foobar")
            region.notifyOnEntry = true
            region.notifyOnExit = true

            locationManager.startMonitoring(for: region)
        }
    }

    fileprivate func buildLocationManager() -> CLLocationManager {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }
}

extension GeofencingController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            pendingLocations.forEach { startMonitoring(location: $0) }
            pendingLocations = []
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        NSLog("Started monitoring region \"\(region.identifier)\"")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NSLog("Entered region \"\(region.identifier)\"")

        do {
            guard let location = try managedObjectContext.fetch(Location.named(region.identifier)).first else {
                return
            }

            location.startVisit(date: Date())
            try managedObjectContext.save()
        } catch {
            fatalError("Failed to start visit at location \"\(region.identifier)\"")
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NSLog("Exited region \"\(region.identifier)\"")

        do {
            guard let location = try managedObjectContext.fetch(Location.named(region.identifier)).first else { return }
            guard let visit = location.currentVisit() else {
                NSLog("Could not find a current visit at \"\(region.identifier)\"")
                return
            }

            visit.ended = Date()
            try managedObjectContext.save()
        } catch {
            fatalError("Failed to end visit at location \"\(region.identifier)\"")
        }
    }
}
