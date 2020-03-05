//
//  PhotoRiderTests.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import XCTest
import CoreData
import Combine
@testable import PhotoRider

class PhotoRiderTests: XCTestCase {

    // This is location that we want to test, it is the Apple campus.
    fileprivate let location = LocationCoordinate(latitude: 37.33240905, longitude: -122.03051211, uid: "apple campus")
    
    fileprivate let locationPhotoPath = "fake.jpg"
    
    fileprivate var photoSub: AnyCancellable?
    

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    

    func testLocationCoordinateEquatable() {
        let location1 = LocationCoordinate(latitude: 20.0, longitude: 2.0, uid: "location1")
        var location2 = LocationCoordinate(latitude: 20.0, longitude: 2.0, uid: "location1")
        
        // Two locations are equal if they have the same latitude and longitude.
        XCTAssertTrue(location1 == location2)
        
        // Two locations are equal if they have the same latitude and longitude, but not the same uid.
        location2.uid = "location2"
        XCTAssertTrue(location1 == location2)
        
        // Two locations are not equal if they don't have the same latitude.
        location2.longitude = location1.longitude
        location2.latitude = location1.latitude + 1.0
        XCTAssertFalse(location1 == location2)
        
        // Two locations are not equal if they don't have the same longitude.
        location2.latitude = location1.latitude
        location2.longitude = location1.longitude + 1.0
        XCTAssertFalse(location1 == location2)
    }

    func testDownloadPhoto() {
        // Create an expectation for an async task.
        let expectation = XCTestExpectation(description: "Download the location photo.")
        
        let photoDownloader = PhotoDownloader()
        
        // Verify that the photo is downloaded.
        self.photoSub = photoDownloader.photo.sink {
            let locationUid = $0.uid
            let fileUrl = $0.url
            let fileType = $0.url.pathExtension.lowercased()
            
            XCTAssertTrue(locationUid == self.location.uid)
            XCTAssertTrue(fileType == "jpg" || fileType == "jpeg" || fileType == "png")
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileUrl.path))
            
            // Now delete all the photos.
            photoDownloader.deleteAllPhotos { _ in
                XCTAssertFalse(FileManager.default.fileExists(atPath: fileUrl.path))
                
                // Fulfill the expectation to indicate that the background task has finished successfully.
                expectation.fulfill()
            }
        }
        
        // Create a location publisher that sends the location.
        let locationPublisher = PassthroughSubject<LocationCoordinate?, Never>()
        
        // Subscribe to receive the locations that we want the photos.
        photoDownloader.start(withPublisher: locationPublisher.eraseToAnyPublisher())
        
        // Reset the photo directory.
        photoDownloader.deleteAllPhotos { _ in
            // Send the location and wait for the photo.
            locationPublisher.send(self.location)
        }
        
        // Wait until the expectation is fulfilled, with a timeout of 10 seconds.
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSaveLocation() {
        // Create an expectation for an async task.
        let expectation = XCTestExpectation(description: "Save the location.")
        
        // Create a location publisher that sends the location.
        let locationPublisher = PassthroughSubject<LocationCoordinate?, Never>()
        
        // Create a location publisher that sends the photo.
        let photoPublisher = PassthroughSubject<LocationPhoto, Never>()
        
        // Get the context to write in.
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = (UIApplication.shared.delegate as? AppDelegate)!.persistentContainer.viewContext
        
        let locationSaver = LocationSaver()
        locationSaver.context = context
        
        // Subscribe to receive the locations that we want to save.
        locationSaver.start(withLocationPublisher: locationPublisher.eraseToAnyPublisher(), andPhotosPublisher: photoPublisher.eraseToAnyPublisher())
        
        // Send the location and the photo.
        DispatchQueue.global(qos: .background).async {
            locationPublisher.send(self.location)
            sleep(1)
            photoPublisher.send(LocationPhoto(uid: self.location.uid, url: URL(fileURLWithPath: self.locationPhotoPath)))
            sleep(1)
            
            context.persistentStoreCoordinator!.perform {
                let request: NSFetchRequest<Location> = Location.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "uid like[cd] %@", self.location.uid)
                
                var found = false
                
                while !found {
                    do {
                        let result = try context.fetch(request)
                        
                        if let location = result.first {
                            XCTAssertTrue(location.latitude == self.location.latitude)
                            XCTAssertTrue(location.longitude == self.location.longitude)
                            XCTAssertNotNil(location.photo)
                            XCTAssertTrue(location.photo == self.locationPhotoPath)
                            
                            found = true
                            
                            // Fulfill the expectation to indicate that the background task has finished successfully.
                            expectation.fulfill()
                        }
                    } catch {
                        debugPrint("Can not retrieve the location object, error: \(error)")
                    }
                }
            }
        }
        
        // Wait until the expectation is fulfilled, with a timeout of 10 seconds.
        wait(for: [expectation], timeout: 10.0)
    }
}
