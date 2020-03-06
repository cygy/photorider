//
//  PhotoDownloader.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import Foundation
import Combine
import CoreData
import UIKit

/*
 The PhotoDownloader class is responsible for downloading the photos associated to a location.
 
 It receives the location from a publisher and it searches a photo from Flickr associated to this location.
 Once it gets the list of photos, a photo with appropriate size is selected, downloaded and published.
 
 The PhotoDownloader must be available across the application so it implements the singleton pattern.
 */

// MARK: - PhotoDownloader Class

class PhotoDownloader {
    
    // MARK: - Properties
    
    fileprivate var locationSub: AnyCancellable? {
        didSet {
            oldValue?.cancel()
        }
    }
    fileprivate var requestSubs = Set<AnyCancellable>()
    fileprivate let downloadedPhotos = PassthroughSubject<LocationPhoto, Never>()
    
    // The screen width is used to select the photos with an appropriate size.
    var screenWidth = Int(UIScreen.main.bounds.width)
    
    
    // MARK: - Lifecycle
    
    deinit {
        self.locationSub?.cancel()
    }
    
    
    // MARK: - Private methods
    
    fileprivate func downloadPhoto(from locationCoordinate: LocationCoordinate) {
        let locationUID = locationCoordinate.uid
        
        let photosListURL = URL(string: "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(flickrAPIKey)&lat=\(locationCoordinate.latitude)&lon=\(locationCoordinate.longitude)&format=json&accuracy=16&content_type=1&geo_context=2&radius=0.05&radius_units=km&per_page=1&nojsoncallback=1")!
        
        let sub = URLSession.shared.dataTaskPublisher(for: photosListURL)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw APIError.statusCode
                }
                return output.data
            }
            .decode(type: PhotosAPIResponse.self, decoder: JSONDecoder())
            .tryMap { photos in
                guard let id = photos.photos.photo.first?.id else {
                    throw APIError.missingPhoto
                }
                return id
            }
            .flatMap { id in
                return self.getPhotoSource(with: id)
            }
            .sink(receiveCompletion: { completion in
            }) { [unowned self] source in
                self.downloadPhoto(from: source, andCompletion:{ [unowned self] fileURL in
                    debugPrint("PhotoDownloader: saved photo of the location \(locationUID) to \(fileURL.absoluteString).")
                    self.downloadedPhotos.send(LocationPhoto(uid: locationUID, url: fileURL))
                })
            }
        
        sub.store(in: &self.requestSubs)
    }
    
    fileprivate func getPhotoSource(with photoId: String) -> AnyPublisher<String, Error> {
        let photoPropertiesURL = URL(string: "https://www.flickr.com/services/rest/?method=flickr.photos.getSizes&api_key=\(flickrAPIKey)&photo_id=\(photoId)&format=json&nojsoncallback=1")!
        
        return URLSession.shared.dataTaskPublisher(for: photoPropertiesURL)
            .tryMap { output in
                guard let response = output.response as? HTTPURLResponse, response.statusCode == 200 else {
                    throw APIError.statusCode
                }
                return output.data
            }
            .decode(type: SizesAPIResponse.self, decoder: JSONDecoder())
            .tryMap { sizes in
                let filteredSizes = sizes.sizes.size.filter({ $0.width >= self.screenWidth && $0.width <= self.screenWidth*2 })
                
                guard let source = filteredSizes.first?.source else {
                    throw APIError.missingSize
                }
                
                return source
            }
            .eraseToAnyPublisher()
    }
    
    // TODO: fix this function to return a AnyPublisher<String, Error> instead of a completion block.
    fileprivate func downloadPhoto(from source: String, andCompletion completion: ((URL) -> Void)?) {
        let photoURL = URL(string: source)!
        
        let downloadTask = URLSession.shared.downloadTask(with: photoURL) { (url, response, error) in
            guard let r = response as? HTTPURLResponse, r.statusCode == 200, error == nil,  let fileURL = url else {
                return
            }

            do {
                let documentsURL = try FileManager.default.url(for: .documentDirectory,
                                                               in: .userDomainMask,
                                                               appropriateFor: nil,
                                                               create: false)
                let savedURL = documentsURL.appendingPathComponent(photoURL.lastPathComponent)
                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                completion?(savedURL)
            } catch {
                debugPrint("PhotoDownloader: can not move downloaded photo, error \(error)")
            }
        }
        
        downloadTask.resume()
    }
}


// MARK: - PhotoDownloaderProtocol

extension PhotoDownloader: PhotoDownloaderProtocol {
    
    var photo: AnyPublisher<LocationPhoto, Never> {
        return self.downloadedPhotos.eraseToAnyPublisher()
    }
    
    func start(withPublisher publisher: AnyPublisher<LocationCoordinate?, Never>) {
        self.locationSub = publisher.sink { [unowned self] locationCoordinate in
            guard let locationCoordinate = locationCoordinate else {
                return
            }
                
            self.downloadPhoto(from: locationCoordinate)
        }
    }
    
    func deleteAllPhotos(withCompletion completion: ((Error?) -> Void)?) {
        // The photos are deleted in the background queue to not block the UI thread.
        DispatchQueue.global(qos: .background).async {
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsUrl,
                                                                            includingPropertiesForKeys: nil,
                                                                            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                for fileURL in fileURLs {
                    try FileManager.default.removeItem(at: fileURL)
                }
                
                debugPrint("PhotoDownloader: deleted \(fileURLs.count) photos.")
                
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            } catch {
                debugPrint("PhotoDownloader: can not delete downloaded photo, error \(error)")
                
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }
    }
}
