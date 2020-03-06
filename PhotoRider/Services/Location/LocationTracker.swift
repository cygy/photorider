//
//  LocationTracker.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

/*
 The LocationTracker class is responsible for managing the location services:
    - request the authorization
    - start tracking the location
    - stop tracking the location
 
 Three properties can be subscribed:
    - to know when the application is authorized to use the location services
    - to know when the location services ara available
    - to know the current location of the user
 
 The LocationTracker adopts the protocol CLLocationManagerDelegate
 but it is facaded: no one knows about it outside this file.
 
 The LocationTracker must be available across the application so it implements the singleton pattern.
 */

// MARK: - LocationTracker Class

class LocationTracker: NSObject {
    
    // MARK: - Properties
    
    fileprivate var locationManager: LocationManagerProtocol
    
    // When the property 'active' is set to true
    // LocationTracker knows that the location must be updated.
    private(set) var active = false
    
    public var distance = 100.0 {
        didSet {
            locationManager.distanceFilter = distance
        }
    }
    
    @Published fileprivate var _authorized = false
    @Published fileprivate var _locationServicesEnabled = false
    @Published fileprivate var _location: LocationCoordinate?
    
    
    // MARK: - Lifecycle
    
    override convenience init() {
        self.init(withLocationManager:CLLocationManager())
    }
    
    init(withLocationManager locationManager: LocationManagerProtocol) {
        self.locationManager = locationManager
        
        super.init()
        
        self.locationManager.pausesLocationUpdatesAutomatically = true // Ensure that is set to true to save power.
        self.locationManager.activityType = .fitness
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.distanceFilter = self.distance
        self.locationManager.delegate = self
    }
}


// MARK: - LocationTrackerProtocol

extension LocationTracker: LocationTrackerProtocol {
    
    var authorized: Published<Bool>.Publisher {
        return $_authorized
    }
    
    var locationServicesEnabled: Published<Bool>.Publisher {
       return $_locationServicesEnabled
    }
    
    var location: Published<LocationCoordinate?>.Publisher {
        return $_location
    }
    
    func requestAuthorization() throws {
        guard self._locationServicesEnabled else {
            debugPrint("LocationTracker: can not request authorization because the location services are disabled.")
            throw LocationTrackerError.locationServicesDisabled
        }

        debugPrint("LocationTracker: request authorization.")
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func start() throws {
        debugPrint("LocationTracker: activated the location tracking.")
        self.active = true
        
        guard self._locationServicesEnabled else {
            debugPrint("LocationTracker: can not track location because the location services are disabled.")
            throw LocationTrackerError.locationServicesDisabled
        }
        
        guard self._authorized else {
            debugPrint("LocationTracker: can not track location because the user denied the location services.")
            throw LocationTrackerError.unauthorized
        }
        
        debugPrint("LocationTracker: start the location tracking.")
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.startUpdatingLocation()
    }
    
    func stop() {
        debugPrint("LocationTracker: stop the location tracking.")
        self.locationManager.allowsBackgroundLocationUpdates = false
        self.locationManager.stopUpdatingLocation()
        self.active = false
    }
}


// MARK: - CLLocationManagerDelegate

extension LocationTracker: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        debugPrint("LocationTracker: authorization status changed to \(status.rawValue)")
        
        self._locationServicesEnabled = (status != .denied && status != .restricted)
        self._authorized = (status == .authorizedAlways || status == .authorizedWhenInUse)
        
        guard self._authorized else {
            self.stop()
            return
        }
        
        if self.active {
            try? self.start()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        debugPrint("LocationTracker: fail with error \(error.localizedDescription)")
        
        // Location updates are not authorized.
        if let error = error as? CLError, error.code == .denied {
            self.stop()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Only the most recent updates are kept.
        guard let lastLocation = locations.last, lastLocation.timestamp.timeIntervalSinceNow > -60 else {
            return
        }
        
        let currentLocation = LocationCoordinate(latitude: lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude)
        
        guard self._location != currentLocation else {
            return
        }
        
        // Ensure that the new location is far enough from the last saved location.
        if let currentSavedLocation = self._location {
            let location = CLLocation(latitude: CLLocationDegrees(currentSavedLocation.latitude), longitude: CLLocationDegrees(currentSavedLocation.longitude))
            
            guard lastLocation.distance(from: location) > self.distance else {
                return
            }
        }
        
        self._location = currentLocation
        
        debugPrint("LocationTracker: new location \(String(describing: currentLocation.latitude)) / \(String(describing: currentLocation.longitude))")
    }
}
