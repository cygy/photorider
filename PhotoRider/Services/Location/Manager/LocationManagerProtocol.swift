//
//  LocationManagerProtocol.swift
//  PhotoRider
//
//  Created by Cyril on 06/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation
import CoreLocation

// The LocationManagerProtocol protocol is defined to easily test CLLocationManager.
// This protocol defines the properties and the functions of CLLocationManager used in the application.
protocol LocationManagerProtocol {
    var delegate: CLLocationManagerDelegate? { get set }
    var distanceFilter: CLLocationDistance { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var activityType: CLActivityType { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var allowsBackgroundLocationUpdates: Bool { get set }
    
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

// Let's declare that CLLocationManager conforms to the LocationManagerProtocol protocol.
// So CLLocationManager can be used as default.
extension CLLocationManager: LocationManagerProtocol {
}
