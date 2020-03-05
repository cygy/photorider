![Photo Rider](https://github.com/cygy/photorider/raws/appicon.png)

# Photo Rider

An iOS application to download photos of your ride!

*This is a demo application to use the location services and the Combine framework.*

## Architecture

This application uses a traditional *MVC* architecture with *storyboards*.
The *Combine* framework is used to manage the events.
The *CoreData* framework is used to save the data on disk.

## Services

The application is based on three "services":
- LocationTracker which is responsible for requesting authorization to use the location from the user and sending the updated location with a Publisher.
- PhotoDownloader which is responsible for downloading a photo bound to a location. It subscribes to the LocationTracker's publisher to know the current location. A photo is not save twice.
- LocationSaver which is responsible for saving on disk the consecutive locations of the walk. It subscribes to the LocationTracker's publisher to know the locations to save and to the PhotoDownloader's publisher to know the photos to save.

Based on the dependency injection pattern, these services implement a well-defined *protocol*.

## Views

There are two UIViewController classes:
- PhotosViewController which is in charge to display the photos of the ride
- StartViewController, the main viewcontroller, which invites the user to start the ride

## Documentation

### The location services

There are some documentations to implement the locaction services in the application:
- Adding Location Services to Your App: https://developer.apple.com/documentation/corelocation/adding_location_services_to_your_app
- Using the Standard Location Service: https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/using_the_standard_location_service
- Differences between "When In Use Authorization" and "Always Authorization" : https://developer.apple.com/documentation/corelocation/choosing_the_location_services_authorization_to_request
- Ask for authorization to the user (add the messages to the Info.plist file): https://developer.apple.com/documentation/corelocation/requesting_authorization_for_location_services


### The Flickr API

The application uses the Flickr API.
- retrieve the photos for a location: https://www.flickr.com/services/api/flickr.photos.geo.photosForLocation.html
- get the differents sizes of a photo: https://www.flickr.com/services/api/flickr.photos.getSizes.html
