//
//  ViewController.swift
//  Tracking
//
//  Created by Jose Manuel on 27/11/19.
//  Copyright © 2019 Jose Manuel. All rights reserved.
//

import MapKit
import CoreLocation
import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    let regionMeters : Double =  100
    private var locationList: [CLLocation] = []
    private var distance = Measurement(value: 0, unit: UnitLength.meters)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLocationServices()
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        
    }
    
    func statusLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            //setup our location manager
            setupLocationManager()
            statusLocationAuthorization()
        } else {
            // show alert letting the user
        }
    }
    
    func userLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func configMap(){
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.userTrackingMode = MKUserTrackingMode.follow
    }
    
    func statusLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            configMap()
            userLocation()
            locationManager.startUpdatingLocation()
        case .denied:
            break
        case .restricted:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            fatalError()
        }
    }
}

// MARK: - Location Manager Delegate

extension ViewController: CLLocationManagerDelegate {
     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
           
        //drawing path or route covered
           for newLocation in locations {
             let howRecent = newLocation.timestamp.timeIntervalSinceNow
             guard newLocation.horizontalAccuracy < 20 && abs(howRecent) < 10 else { continue }
             
             if let lastLocation = locationList.last {
               let delta = newLocation.distance(from: lastLocation)
               distance = distance + Measurement(value: delta, unit: UnitLength.meters)
               let coordinates = [lastLocation.coordinate, newLocation.coordinate]
               mapView.addOverlay(MKPolyline(coordinates: coordinates, count: 2))
               let region = MKCoordinateRegion(center: newLocation.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
               mapView.setRegion(region, animated: true)
             }
             
             locationList.append(newLocation)
           }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        statusLocationAuthorization()
    }
}

// MARK: - Map View Delegate

extension ViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      guard let polyline = overlay as? MKPolyline else {
          return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 3
        return renderer
      }
}
