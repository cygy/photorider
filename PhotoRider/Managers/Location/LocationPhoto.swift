//
//  LocationPhoto.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation

// A photo of a location is simply represented by the location's UID
// and the local url of the photo.
struct LocationPhoto {
    let uid: String
    let url: URL
}
