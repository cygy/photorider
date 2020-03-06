//
//  LocationSaverError.swift
//  PhotoRider
//
//  Created by Cyril on 06/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation


// These are the errors used by the LocationSaver.

enum LocationSaverError: Error {
    // The NSMAnagedObjectContext of the lcoation saver is nil.
    case undefinedContext
}
