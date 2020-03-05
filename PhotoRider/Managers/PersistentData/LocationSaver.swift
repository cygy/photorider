//
//  LocationSaver.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation
import Combine
import CoreData

/*
 The LocationSaver has two jobs:
    - saving on disk the locations
    - and saving on disk the downloaded photos of these locations
 
 When a new walk is starting it deletes all the previous saved locations.
 
 The LocationSaver must be available across the application so it implements the singleton pattern.
 */

class LocationSaver: LocationSaverProtocol {
    
    // MARK: - Properties
    
    fileprivate var locationSub: AnyCancellable? {
           didSet {
               oldValue?.cancel()
           }
       }
    fileprivate var photosSub: AnyCancellable? {
           didSet {
               oldValue?.cancel()
           }
       }
    
    public var context: NSManagedObjectContext?
    
    
    // MARK: - Lifecycle
    
    deinit {
        self.locationSub?.cancel()
        self.photosSub?.cancel()
    }
    
    
    // MARK: - Public methods
    
    func start(withLocationPublisher locationPublisher: AnyPublisher<LocationCoordinate?, Never>, andPhotosPublisher photosPublisher: AnyPublisher<LocationPhoto, Never>) {
        guard let context = self.context else {
            fatalError("LocationSaver: can not start saving locations and photos without defining a NSManagedObjectContext object.")
        }
        
        // Saves the locations received by the publisher.
        self.locationSub = locationPublisher
            .sink { locationCoordinate in
                guard let locationCoordinate = locationCoordinate else {
                    return
                }

                context.performAndWait {
                    let location = Location(context: context)
                    location.uid = locationCoordinate.uid
                    location.latitude = locationCoordinate.latitude
                    location.longitude = locationCoordinate.longitude
                    location.date = Date()

                    do {
                        try context.save()
                        try context.parent?.save()
                        debugPrint("LocationSaver: saved location at \(location.latitude) / \(location.longitude).")
                    } catch let error {
                        debugPrint("LocationSaver: can not save new location object to the context: \(error)")
                    }
                }
            }
        
        // Updates the location with the saved photos.
        self.photosSub = photosPublisher
            .sink { locationPhoto in
                context.performAndWait {
                    do {
                        let request: NSFetchRequest<Location> = Location.fetchRequest()
                        request.fetchLimit = 1
                        request.predicate = NSPredicate(format: "uid like[cd] %@", locationPhoto.uid)
                        
                        let result = try context.fetch(request)
                        result.first?.photo = locationPhoto.url.lastPathComponent
                        
                        if context.hasChanges {
                            try context.save()
                            try context.parent?.save()
                            debugPrint("LocationSaver: saved photo of the location to the context.")
                        }
                    } catch let error {
                        debugPrint("LocationSaver: can not save photo of the location object to the context: \(error)")
                    }
                }
            }
    }
    
    func deleteAllLocations() {
        guard let context = self.context else {
            return
        }
        
        context.perform {
            do {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                deleteRequest.resultType = .resultTypeObjectIDs
                
                let result = try context.persistentStoreCoordinator?.execute(deleteRequest, with: context) as? NSBatchDeleteResult
                
                let deletedObjects = result?.result as? [NSManagedObjectID] ?? []
                let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: deletedObjects]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                
                debugPrint("LocationSaver: deleted all the locations.")
            } catch {
                debugPrint("LocationSaver: can not delete all the locations: \(error)")
            }
        }
    }
}
