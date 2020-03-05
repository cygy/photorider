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

class LocationTracker: NSObject, CLLocationManagerDelegate, LocationTrackerProtocol {
    
    // MARK: - Properties
    
    private let nativeLocationManager = CLLocationManager()
    
    // When the property 'active' is set to true
    // LocationTracker knows that the location must be updated.
    private var active = false
    
    var distance = 100.0 {
        didSet {
            nativeLocationManager.distanceFilter = distance
        }
    }
    
    @Published fileprivate var _authorized = false
    @Published fileprivate var _locationServicesEnabled = false
    @Published fileprivate var _location: LocationCoordinate?
    
    var authorized: Published<Bool>.Publisher {
        return $_authorized
    }
    
    var locationServicesEnabled: Published<Bool>.Publisher {
       return $_locationServicesEnabled
    }
    
    var location: Published<LocationCoordinate?>.Publisher {
        return $_location
    }
    
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        
        self.nativeLocationManager.pausesLocationUpdatesAutomatically = true // Ensure that is set to true to save power.
        self.nativeLocationManager.activityType = .fitness
        self.nativeLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.nativeLocationManager.distanceFilter = self.distance
        self.nativeLocationManager.delegate = self
    }
    
    
    // MARK: - Public functions
    
    func requestAuthorization() throws {
        guard self._locationServicesEnabled else {
            debugPrint("LocationTracker: can not request authorization because the location services are disabled.")
            throw LocationTrackerError.locationServicesDisabled
        }
        
        guard CLLocationManager.authorizationStatus() == .notDetermined else {
            debugPrint("LocationTracker: can not request authorization because it was already requested.")
            throw LocationTrackerError.authorizationAlreadyRequested
        }

        debugPrint("LocationTracker: request authorization.")
        self.nativeLocationManager.requestWhenInUseAuthorization()
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
        self.nativeLocationManager.allowsBackgroundLocationUpdates = true
        self.nativeLocationManager.startUpdatingLocation()
    }
    
    func stop() {
        debugPrint("LocationTracker: stop the location tracking.")
        self.nativeLocationManager.allowsBackgroundLocationUpdates = false
        self.nativeLocationManager.stopUpdatingLocation()
        self.active = false
    }
    
    
    // MARK: - CLLocationManagerDelegate functions
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        debugPrint("LocationTracker: authorization status changed to \(status.rawValue)")
        
        self._locationServicesEnabled = CLLocationManager.locationServicesEnabled()
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
