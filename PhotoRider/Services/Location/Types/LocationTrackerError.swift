//
//  LocationTrackerError.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation

// These are the errors used by the LocationTracker.

enum LocationTrackerError: Error {
    // The location services are disabled, the location can not be tracked.
    // The user must enable the location services in the device settings.
    case locationServicesDisabled
    
    // The use of the location services by the application was denied by the user.
    // The user must allow the application the use of the location services in the application settings.
    case unauthorized
}
