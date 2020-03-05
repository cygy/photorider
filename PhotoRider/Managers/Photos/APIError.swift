//
//  APIError.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation

enum APIError: LocalizedError {
    // Used if the status code of an API response is different of 200.
    case statusCode
    
    // Used if a photo does not exist for a location.
    case missingPhoto
    
    // Used if a photo does not have a size adapted to the device screen.
    case missingSize
}
