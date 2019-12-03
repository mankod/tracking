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
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton:  UIButton!
    @IBOutlet weak var distanceLabel: UILabel!
    
    private var tracking: Tracking?
    let locationManager = CLLocationManager()
    let regionMeters : Double =  100
    private var locationList: [CLLocation] = []
    private var distance = Measurement(value: 0, unit: UnitLength.meters)
    private var seconds = 0
    private var timer: Timer?
    private var nameTrack : String = ""
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Tracking"
        setupLocationManager()
    }
    
    @IBAction func stopTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Final de la ruta",
                                                message: "¿Deseas finalizar tu recorrido?",
                                                preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Guardar", style: .default) { _ in
            self.stopTrackSession()
            self.promptForAnswer()
        })
        alertController.addAction(UIAlertAction(title: "Descartar", style: .destructive) { _ in
            self.stopTrackSession()
            _ = self.navigationController?.popToRootViewController(animated: true)
        })
        present(alertController, animated: true)
    }
    func promptForAnswer() {
        let ac = UIAlertController(title: "Nombre del track a guardar ? ", message: nil, preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "OK", style: .default) { [unowned ac] _ in
            self.nameTrack = ac.textFields![0].text ?? " "
            self.saveTrackSession()
        }

        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    
    @IBAction func startTapped() {
        self.startTrackSession()
    }
    
    // MARK: - saveTrackSession
    private func saveTrackSession() {
        let newTrack = Tracking(context: CoreDataStack.context)
        newTrack.distance = distance.value
        newTrack.duration = Int16(seconds)
        newTrack.timestamp = Date()
        newTrack.name = self.nameTrack
        
        for location in locationList {
            let locationObject = Location(context: CoreDataStack.context)
            locationObject.timestamp = location.timestamp
            locationObject.latitude = location.coordinate.latitude
            locationObject.longitude = location.coordinate.longitude
            newTrack.addToLocation(locationObject)
        }
        CoreDataStack.saveContext()
        tracking = newTrack
    }
    
    // MARK: - stopTrackSession
    private func stopTrackSession() {
        startButton.isHidden = false
        stopButton.isHidden = true
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - startTrackSession
    private func startTrackSession() {
        startButton.isHidden = true
        stopButton.isHidden = false
        configMap()
        mapView.removeOverlays(mapView.overlays)
        seconds = 0
        distance = Measurement(value: 0, unit: UnitLength.meters)
        locationList.removeAll()
        updateDisplay()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.eachSecond()
        }
        setupLocationManager()
    }
    
    // MARK: - eachSecond
    func eachSecond() {
        seconds += 1
        updateDisplay()
    }
    
    //MARK: - updateDisplay
    func updateDisplay() {
        let formattedDistance = FormatDisplay.distance(distance)
        let formattedTime = FormatDisplay.time(seconds)
        print("Distance 🏃🏻‍♂️ :  \(formattedDistance)")
        print("Time :  \(formattedTime)")
    }
    
    //MARK: - setupLocationManager
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    //MARK: - userLocation
    func userLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionMeters, longitudinalMeters: regionMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    //MARK: - configMap
    func configMap(){
        mapView.userTrackingMode = .followWithHeading
        mapView.showsUserLocation = true
        mapView.mapType = MKMapType(rawValue: 0)!
        mapView.userTrackingMode = MKUserTrackingMode.follow
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
}

// MARK: - Map View Delegate

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 3
        return renderer
    }
}
