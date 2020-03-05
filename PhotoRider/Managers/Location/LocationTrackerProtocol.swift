//
//  LocationTrackerProtocol.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation
import Combine

protocol LocationTrackerProtocol {
    // Return true if the application is authorized to use the location of the user.
    var authorized: Published<Bool>.Publisher { get }
    
    // Return true if the location sevices is available on the current device.
    var locationServicesEnabled: Published<Bool>.Publisher { get }
    
    // Return the last location coordinate of the user.
    var location: Published<LocationCoordinate?>.Publisher { get }
    
    // Method to request the authorization to use the location of the user.
    // The authorization will be requested only once.
    // It throws an error if the location services are not available or the authorization was already requested.
    func requestAuthorization() throws
    
    // Method to start updating the location of the user.
    // It throws an error if the location services are not available or they are denied by the user.
    func start() throws
    
    // Method to stop updating the location of the user.
    // Must be called if the application does not need anymore the location.
    func stop()
}
