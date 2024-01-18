//
//  ViewController.swift
//  LocationSnapshot
//
//  Created by Shane Whitehead on 7/12/18.
//  Copyright © 2018 Beam Communications. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {

	@IBOutlet weak var mapPreviewImageView: UIImageView!
    @IBOutlet weak var scenePreviewImageView: UIImageView!

	var locationManager = CLLocationManager()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mapPreviewImageView.layer.cornerRadius = 20
		mapPreviewImageView.layer.borderColor = UIColor.darkGray.cgColor
		mapPreviewImageView.layer.borderWidth = 1
		mapPreviewImageView.clipsToBounds = true

        scenePreviewImageView.layer.cornerRadius = 20
        scenePreviewImageView.layer.borderColor = UIColor.darkGray.cgColor
        scenePreviewImageView.layer.borderWidth = 1
        scenePreviewImageView.clipsToBounds = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.delegate = self
        
        guard locationManager.authorizationStatus.isAuthorised else {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
	}
    
    func snapshotMapAt(_ location: CLLocation) async throws -> UIImage? {
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        options.showsBuildings = true
        
        let config = MKStandardMapConfiguration()
        config.pointOfInterestFilter = MKPointOfInterestFilter(excluding: [])
        options.preferredConfiguration = config
        
        let snapshot = try await MKMapSnapshotter(options: options).start()
        let snapshotImage = snapshot.image
        let coordinatePoint = snapshot.point(for: location.coordinate)
        
        guard let pinImage = UIImage(named: "Beer") else {
            return nil
        }

        UIGraphicsBeginImageContextWithOptions(snapshotImage.size, true, snapshotImage.scale)
        snapshotImage.draw(at: CGPoint.zero)
        
        let fixedPinPoint = CGPoint(x: coordinatePoint.x - pinImage.size.width / 2, y: coordinatePoint.y - pinImage.size.height)
        pinImage.draw(at: fixedPinPoint)
        
        guard let mapImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        return mapImage
    }
    
    func snapshotStreetViewAt(_ location: CLLocation) async throws -> UIImage? {
        guard let scene = try await MKLookAroundSceneRequest(coordinate: location.coordinate).scene else { return nil }
        let options = MKLookAroundSnapshotter.Options()
        options.size = CGSize(width: 256, height: 256)
        let image = try await MKLookAroundSnapshotter(scene: scene, options: options).snapshot
        return image.image
    }

}

extension CLAuthorizationStatus {
    var isAuthorised: Bool {
        switch self {
        case .notDetermined, .restricted, .denied: return false
        case .authorizedAlways, .authorizedWhenInUse: return true
        }
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined, .restricted, .denied:
            break
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        }
    }
    
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = manager.location else { return }
		
		locationManager.stopUpdatingLocation()
        
        Task {
            mapPreviewImageView.image = try await snapshotMapAt(location)
            scenePreviewImageView.image = try await snapshotStreetViewAt(location)
        }
	}
}

