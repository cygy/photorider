//
//  LocationCoordinate.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation

// A location is simply represented by its coordinate
// and a UID to track it along the application.
struct LocationCoordinate {
    var latitude: Double
    var longitude: Double
    var uid = UUID().uuidString
}

// Adopts the Equatable protocol.
extension LocationCoordinate: Equatable {
    static func == (lhs: LocationCoordinate, rhs: LocationCoordinate) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
