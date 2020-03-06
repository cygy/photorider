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
import CoreLocation
@testable import PhotoRider

class PhotoRiderTests: XCTestCase {
    
    // MARK: - Properties

    // This is location that we want to test, it is the Apple campus.
    fileprivate let initialLocation = LocationCoordinate(latitude: 37.33240905, longitude: -122.03051211, uid: "apple campus")
    fileprivate let parisLocation = LocationCoordinate(latitude: 48.8534, longitude: 2.3488, uid: "Paris")
    fileprivate let londonLocation = LocationCoordinate(latitude: 51.508112, longitude: -0.075949, uid: "London")
    
    fileprivate let locationPhotoPath = "fake.jpg"
    
    fileprivate var photoSub: AnyCancellable?
    
    fileprivate let unusedLocationManager = CLLocationManager()
    fileprivate let locationManager = LocationManagerTest()
    fileprivate var locationTracker: LocationTracker?
    
    
    // MARK: - Set up

    override func setUp() {
        self.locationTracker = LocationTracker(withLocationManager: self.locationManager)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    // MARK: - LocationCoordiante

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
    
    
    // MARK: - PhotoDownloader

    func testDownloadPhotoWithSuccess() {
        // Create an expectation for an async task.
        let expectation = XCTestExpectation(description: "Download the location photo.")
        
        let photoDownloader = PhotoDownloader()
        
        // Verify that the photo is downloaded.
        self.photoSub = photoDownloader.photo.sink {
            let locationUid = $0.uid
            let fileUrl = $0.url
            let fileType = $0.url.pathExtension.lowercased()
            
            XCTAssertTrue(locationUid == self.initialLocation.uid)
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
            locationPublisher.send(self.initialLocation)
        }
        
        // Wait until the expectation is fulfilled, with a timeout of 10 seconds.
        wait(for: [expectation], timeout: 10.0)
    }
    
    
    // MARK: - LocationSaver
    
    func testCanNotSaveOrDeleteLocationWithoutContext() {
        let locationSaver = LocationSaver()
        
        let locationPublisher = PassthroughSubject<LocationCoordinate?, Never>()
        let photoPublisher = PassthroughSubject<LocationPhoto, Never>()
        
        do {
            try locationSaver.start(withLocationPublisher: locationPublisher.eraseToAnyPublisher(), andPhotosPublisher: photoPublisher.eraseToAnyPublisher())
        } catch LocationSaverError.undefinedContext {
           // OK, expected error.
       } catch {
           XCTFail("Unexpected error: \(error)")
       }
        
        do {
            try locationSaver.deleteAllLocations()
        } catch LocationSaverError.undefinedContext {
           // OK, expected error.
       } catch {
           XCTFail("Unexpected error: \(error)")
       }
    }
    
    func testSaveLocationAndPhotoWithSuccess() {
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
        do {
            try locationSaver.start(withLocationPublisher: locationPublisher.eraseToAnyPublisher(), andPhotosPublisher: photoPublisher.eraseToAnyPublisher())
        } catch {
            XCTFail("Can not start the location saver service, error: \(error)")
        }
        
        // Send the location and the photo.
        DispatchQueue.global(qos: .background).async {
            locationPublisher.send(self.initialLocation)
            sleep(1)
            photoPublisher.send(LocationPhoto(uid: self.initialLocation.uid, url: URL(fileURLWithPath: self.locationPhotoPath)))
            sleep(1)
            
            context.persistentStoreCoordinator!.perform {
                let request: NSFetchRequest<Location> = Location.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "uid like[cd] %@", self.initialLocation.uid)
                
                var found = false
                
                while !found {
                    do {
                        let result = try context.fetch(request)
                        
                        if let location = result.first {
                            XCTAssertTrue(location.latitude == self.initialLocation.latitude)
                            XCTAssertTrue(location.longitude == self.initialLocation.longitude)
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
    
    
    // MARK: - LocationTracker
    
    func testTrackLocationWithSuccess() {
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .authorizedWhenInUse)

        XCTAssert(self.locationTracker?.active == false)
        
        do {
            try self.locationTracker?.requestAuthorization()
            XCTAssert(self.locationTracker?.active == false)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        do {
            try self.locationTracker?.start()
            XCTAssert(self.locationTracker?.active == true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Send the initial location.
        let expectation = XCTestExpectation(description: "Get the initial location.")
        let sub = self.locationTracker?.location.sink(receiveValue: { locationCoordinate in
            guard let locationCoordinate = locationCoordinate else {
                return
            }
            
            XCTAssertTrue(locationCoordinate.latitude == self.initialLocation.latitude)
            XCTAssertTrue(locationCoordinate.longitude == self.initialLocation.longitude)
            expectation.fulfill()
        })
        
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(latitude: self.initialLocation.latitude, longitude: self.initialLocation.longitude)])
        wait(for: [expectation], timeout: 2.0)
        
        // Stop tracking.
        self.locationTracker?.stop()
        XCTAssert(self.locationTracker?.active == false)
        
        sub?.cancel()
    }
    
    func testDoNotTrackOldLocation() {
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        do {
            try self.locationTracker?.start()
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        let expectation = XCTestExpectation(description: "Do not get old location.")
        let sub = self.locationTracker?.location.sink(receiveValue: { locationCoordinate in
            guard let locationCoordinate = locationCoordinate else {
                return
            }
            
            XCTAssertTrue(locationCoordinate.latitude == self.parisLocation.latitude)
            XCTAssertTrue(locationCoordinate.longitude == self.parisLocation.longitude)
            expectation.fulfill()
        })
        
        // This is must be filtered, the location tracker would not receive it.
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(coordinate: CLLocationCoordinate2D(latitude: CLLocationDegrees(self.londonLocation.latitude), longitude: self.londonLocation.longitude), altitude: CLLocationDistance(100.0), horizontalAccuracy: CLLocationAccuracy(10.0), verticalAccuracy: CLLocationAccuracy(10.0), course: CLLocationDirection(10.0), speed: CLLocationSpeed(1), timestamp: Date(timeIntervalSinceNow: -120))])
        
        // The location tracker must receive this location.
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(latitude: self.parisLocation.latitude, longitude: self.parisLocation.longitude)])
        wait(for: [expectation], timeout: 2.0)
        
        sub?.cancel()
    }
    
    func testDoNotTrackSameLocation() {
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        do {
            try self.locationTracker?.start()
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Send the initial location.
        let expectation = XCTestExpectation(description: "Do not track same location.")
        expectation.expectedFulfillmentCount = 2
        
        var countOfLocations = 0
        let sub = self.locationTracker?.location.sink(receiveValue: { locationCoordinate in
            guard let locationCoordinate = locationCoordinate else {
                return
            }
            
            switch countOfLocations {
                case 0:
                    XCTAssertTrue(locationCoordinate.latitude == self.initialLocation.latitude)
                    XCTAssertTrue(locationCoordinate.longitude == self.initialLocation.longitude)
                    break
                case 1:
                    XCTAssertTrue(locationCoordinate.latitude == self.parisLocation.latitude)
                    XCTAssertTrue(locationCoordinate.longitude == self.parisLocation.longitude)
                    break
                default:
                    XCTFail("Can not receive more than 2 locations.")
            }
            
            countOfLocations += 1
            
            expectation.fulfill()
        })
        
        // The location tracker must receive this location.
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(latitude: self.initialLocation.latitude, longitude: self.initialLocation.longitude)])
        
        // This is must be filtered, the location tracker would not receive it.
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(latitude: self.initialLocation.latitude, longitude: self.initialLocation.longitude)])
        
        // The location tracker must receive this location.
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(latitude: self.parisLocation.latitude, longitude: self.parisLocation.longitude)])
        wait(for: [expectation], timeout: 2.0)
        
        sub?.cancel()
    }
    
    func testDoNotTrackClosedLocation() {
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        do {
            try self.locationTracker?.start()
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // The distance between two locations must be greater than 2000km.
        self.locationTracker?.distance = 2000000
        
        // Send the initial location.
        let expectation = XCTestExpectation(description: "Do not track closed locations.")
        expectation.expectedFulfillmentCount = 2
        
        var countOfLocations = 0
        let sub = self.locationTracker?.location.sink(receiveValue: { locationCoordinate in
            guard let locationCoordinate = locationCoordinate else {
                return
            }
            
            switch countOfLocations {
                case 0:
                    XCTAssertTrue(locationCoordinate.latitude == self.parisLocation.latitude)
                    XCTAssertTrue(locationCoordinate.longitude == self.parisLocation.longitude)
                    break
                case 1:
                    XCTAssertTrue(locationCoordinate.latitude == self.initialLocation.latitude)
                    XCTAssertTrue(locationCoordinate.longitude == self.initialLocation.longitude)
                    break
                default:
                    XCTFail("Can not receive more than 2 locations.")
            }
            
            countOfLocations += 1
            
            expectation.fulfill()
        })
        
        // The location tracker must receive this location.
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(latitude: self.parisLocation.latitude, longitude: self.parisLocation.longitude)])
        
        // This is must be filtered, the location tracker would not receive it.
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(latitude: self.londonLocation.latitude, longitude: self.londonLocation.longitude)])
        
        // The location tracker must receive this location.
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didUpdateLocations: [CLLocation(latitude: self.initialLocation.latitude, longitude: self.initialLocation.longitude)])
        wait(for: [expectation], timeout: 2.0)
        
        sub?.cancel()
    }
    
    func testTrackLocationWithAuthorizationNotDetermined() {
        self.locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .notDetermined)
        
        do {
            try self.locationTracker?.requestAuthorization()
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        do {
            try self.locationTracker?.start()
        } catch LocationTrackerError.unauthorized {
            // OK, expected error.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTrackLocationWithAuthorizationDenied() {
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .denied)
        
        do {
            try self.locationTracker?.requestAuthorization()
        } catch LocationTrackerError.locationServicesDisabled {
            // OK, expected error.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        do {
            try self.locationTracker?.start()
        } catch LocationTrackerError.locationServicesDisabled {
            // OK, expected error.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testStopTrackingLocationAfterDenyingAuthorization() {
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        do {
            try self.locationTracker?.start()
            XCTAssert(self.locationTracker?.active == true)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didFailWithError: CLError(.denied))
        
        XCTAssert(self.locationTracker?.active == false)
    }
    
    func testStartTrackingLocationAndUpdateAuthorization() {
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .denied)
        
        XCTAssert(self.locationTracker?.active == false)
        
        try? self.locationTracker?.start()
        
        XCTAssert(self.locationTracker?.active == true)
        
        locationManager.delegate?.locationManager?(self.unusedLocationManager, didChangeAuthorization: .authorizedWhenInUse)
        
        XCTAssert(self.locationTracker?.active == true)
    }
    
    
    // MARK: - ApplicationState
    
    func testApplicationState() {
        let state = ApplicationState()
        
        XCTAssertTrue(state.isStarted() == false)
        
        do {
            try state.start()
            XCTAssertTrue(state.isStarted() == true)
        } catch {
            XCTFail("ApplicationState must start.")
        }
        
        do {
            try state.restart()
            XCTAssertTrue(state.isStarted() == true)
        } catch {
            XCTFail("ApplicationState must start.")
        }
        
        state.stop()
        XCTAssertTrue(state.isStarted() == false)
        
        do {
            try state.restart()
            XCTAssertTrue(state.isStarted() == false)
        } catch {
            XCTFail("ApplicationState must not start.")
        }
    }
}
