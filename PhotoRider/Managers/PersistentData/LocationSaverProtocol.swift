//
//  LocationSaverProtocol.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation
import Combine
import CoreData

protocol LocationSaverProtocol {
    // Start the job of saving location and photos to the device.
    func start(withLocationPublisher locationPublisher: AnyPublisher<LocationCoordinate?, Never>, andPhotosPublisher photosPublisher: AnyPublisher<LocationPhoto, Never>)

    // Delete all the locations saved to the device.
    func deleteAllLocations()
}
