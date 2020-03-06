//
//  ApplicationState.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation

class ApplicationState {
    
    // MARK: - Constants
    
    fileprivate static let UserDefaultsStartedKey = "LocationUpdateStarted"
    
    
    // MARK: - Properties
    
    var locationTracker: LocationTrackerProtocol?
    var locationSaver: LocationSaverProtocol?
    var photoDownloader: PhotoDownloaderProtocol?
    
    
    // MARK: - Public methods
    
    public func restart() throws {
        if isStarted() {
            try start()
        } else {
            stop()
        }
    }
    
    public func start() throws {
        UserDefaults.standard.set(true, forKey: ApplicationState.UserDefaultsStartedKey)
        try self.locationTracker?.start()
    }
    
    public func stop() {
        UserDefaults.standard.set(false, forKey: ApplicationState.UserDefaultsStartedKey)
        self.locationTracker?.stop()
        self.photoDownloader?.deleteAllPhotos(withCompletion: nil)
        
        do {
            try self.locationSaver?.deleteAllLocations()
        } catch {
            debugPrint("ApplicationState: can not delete the locations, error: \(error)")
        }
    }
    
    public func isStarted() -> Bool {
        return UserDefaults.standard.bool(forKey: ApplicationState.UserDefaultsStartedKey)
    }
}
