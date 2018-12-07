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
	
	var locationManager = CLLocationManager()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mapPreviewImageView.layer.cornerRadius = 20
		mapPreviewImageView.layer.borderColor = UIColor.darkGray.cgColor
		mapPreviewImageView.layer.borderWidth = 1
		mapPreviewImageView.clipsToBounds = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		locationManager.requestWhenInUseAuthorization()
		guard CLLocationManager.locationServicesEnabled() else {
			return
		}
		
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
		locationManager.startUpdatingLocation()
	}
	
	func snapshot(_ location: CLLocation) {
		let options = MKMapSnapshotter.Options()
		options.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
		options.showsBuildings = true
		options.showsPointsOfInterest = true
		let queue = DispatchQueue.global(qos: .userInitiated)
		let snapshotter = MKMapSnapshotter(options: options)
		print("Generate image")
		snapshotter.start(with: queue) { (snapshot, error) in
			print("Process image")
			guard error == nil else {
				print("!! \(error!)")
				return
			}
			guard let snapshotImage = snapshot?.image,
				let coordinatePoint = snapshot?.point(for: location.coordinate),
				let pinImage = UIImage(named: "Beer") else {
				print("!! 💀")
				return
			}
			print("Drop pin")
			print(snapshotImage.size)
			UIGraphicsBeginImageContextWithOptions(snapshotImage.size, true, snapshotImage.scale)
			snapshotImage.draw(at: CGPoint.zero)
			
			let fixedPinPoint = CGPoint(x: coordinatePoint.x - pinImage.size.width / 2, y: coordinatePoint.y - pinImage.size.height)
			pinImage.draw(at: fixedPinPoint)
			
			guard let mapImage = UIGraphicsGetImageFromCurrentImageContext() else {
				print("!! 💀☹️")
				return
			}
			
			DispatchQueue.main.async {
				self.mapPreviewImageView.image = mapImage
			}
		}
	}

}

extension ViewController: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = manager.location else { return }
		
		locationManager.stopUpdatingLocation()
		snapshot(location)
	}
}

