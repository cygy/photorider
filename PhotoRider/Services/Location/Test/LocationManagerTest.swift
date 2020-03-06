//
//  LocationManagerTest.swift
//  PhotoRiderTests
//
//  Created by Cyril on 06/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation
import CoreLocation

/*
 This class is used to mockup the native CLLocationManager class in the tests.
 */

class LocationManagerTest: LocationManagerProtocol {
    weak var delegate: CLLocationManagerDelegate?
    
    var distanceFilter: CLLocationDistance = 0.0
    
    var pausesLocationUpdatesAutomatically: Bool = false
    
    var activityType: CLActivityType = .airborne
    
    var desiredAccuracy: CLLocationAccuracy = 0.0
    
    var allowsBackgroundLocationUpdates: Bool = false
    
    func requestWhenInUseAuthorization() {
    }
    
    func startUpdatingLocation() {
    }
    
    func stopUpdatingLocation() {
    }
    
    init() {
    }
}
