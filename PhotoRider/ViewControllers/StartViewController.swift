//
//  StartViewController.swift
//  PhotoRider
//
//  Created by Cyril on 04/03/2020.
//  Copyright © 2020 Cyril GY. All rights reserved.
//

import UIKit
import Combine

/*
 The StartViewController is the main viewcontroller of the application.
 
 Pressing the start button stats updating the location of the user every 100 meters.
 The start button can only be pressed if the location services are available and they are accepted by the user.
 
 If the location services are not enabled a warning is displayed and the start button is hidden.
 If the location services are denied by the user a warning is displayed and the start button is hidden.
 
 This viewcontroller subscribes to the LocationTracker's published properties to update the UI:
    - show or hide the start button
    - show or hide the warning texts about the location services
 */

class StartViewController: UIViewController {
    
    // MARK: - UI Items

    // The start button launches the location tracking while the user is walking.
    @IBOutlet weak var startButton: UIButton!
    
    // If the location services are disabled for this application, a warning is displayed.
    @IBOutlet weak var locationServicesDisabledView: UIView!
    
    // If the user denied the location tracking for this application, a warning is displayed.
    @IBOutlet weak var locationServicesDeniedView: UIView!
    
    
    // MARK: - Model
    
    var hideLocationServicesDisabledTextSub: AnyCancellable?
    var hideLocationServicesDeniedTextSub: AnyCancellable?
    var hideStartButtonSub: AnyCancellable?
    
    
    // MARK: - UI functions
    
    // This action is here to come back from another viewcontroller to this viewcontroller.
    @IBAction func stopUndwind(segue: UIStoryboardSegue) {
        guard let segueIdentifier = segue.identifier else {
            return
        }
        
        // Stop updating the location of the user.
        if segueIdentifier == "stop" {
            AppDelegate.state.stop()
        }
    }
    
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let locationServicesEnabled = AppDelegate.state.locationTracker?.locationServicesEnabled, let authorized = AppDelegate.state.locationTracker?.authorized else {
            return
        }
        
        self.hideLocationServicesDisabledTextSub = locationServicesEnabled
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .assign(to: \.locationServicesDisabledView.isHidden, on: self)
            
        self.hideLocationServicesDeniedTextSub = authorized
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .assign(to: \.locationServicesDeniedView.isHidden, on: self)
        
        self.hideStartButtonSub = Publishers.CombineLatest(locationServicesEnabled, authorized)
            .map { (locationServicesEnabled, authorized) -> Bool in
                return !locationServicesEnabled || !authorized
            }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
            .assign(to: \.startButton.isHidden, on: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !AppDelegate.state.isStarted() else {
            self.performSegue(withIdentifier: "start", sender: self.startButton)
            return
        }

        // Request the authorization of the user to use its location.
        // Don't need to catch the errors because of the Combine subscriptions: the UI is already up-to-date!
        try? AppDelegate.state.locationTracker?.requestAuthorization()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.hideLocationServicesDisabledTextSub?.cancel()
        self.hideLocationServicesDeniedTextSub?.cancel()
        self.hideStartButtonSub?.cancel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueIdentifier = segue.identifier else {
            return
        }
        
        // Start updating the location of the user.
        // Don't need to catch the errors because of the Combine subscriptions: the UI is already up-to-date!
        if segueIdentifier == "start" {
            try? AppDelegate.state.start()
        }
    }
}

