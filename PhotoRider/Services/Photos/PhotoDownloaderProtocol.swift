//
//  PhotoDownloaderProtocol.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation
import Combine

protocol PhotoDownloaderProtocol {
    // Return the last downloaded photo of a location.
    var photo: AnyPublisher<LocationPhoto, Never> { get }
    
    // Start the job of downloading photos with the received locations.
    func start(withPublisher publisher: AnyPublisher<LocationCoordinate?, Never>)
    
    // Delete all the photos donwloaded and stored to the device.
    func deleteAllPhotos(withCompletion completion: ((Error?) -> Void)?)
}
