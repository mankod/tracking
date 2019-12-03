//
//  TrackDetailsViewController.swift
//  Tracking
//
//  Created by Jose Manuel on 02/12/19.
//  Copyright © 2019 Jose Manuel. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import AVFoundation


class TrackDetailsViewController: UIViewController {
    
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    var track: Tracking!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    
    private func configureView() {
        let seconds = Int(track.duration)
        let distance = Measurement(value: track.distance, unit: UnitLength.meters)
        let formattedDistance = FormatDisplay.distance(distance)
        distanceLabel.text = "Distancia:  \(formattedDistance)"
        let formattedDate = FormatDisplay.date(track.timestamp)
        let formattedTime = FormatDisplay.time(seconds)
        timeLabel.text = "Tiempo:  \(formattedTime)"
        dateLabel.text = formattedDate
        loadMap()
    }
    
    func loadMap(){
        guard
            let locations = track.location,
            locations.count > 0,
            let region = mapRegion()
            else {
                let alert = UIAlertController(title: "Error",
                                              message: "Sorry, this run has no locations saved",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
                present(alert, animated: true)
                return
        }
        mapView.setRegion(region, animated: true)
        mapView.addOverlays(polyLine())
    }
    
    private func mapRegion() -> MKCoordinateRegion? {
        guard
            let locations = track.location,
            locations.count > 0
            else {
                return nil
        }
        
        let latitudes = locations.map { location -> Double in
            let location = location as! Location
            return location.latitude
        }
        
        let longitudes = locations.map { location -> Double in
            let location = location as! Location
            return location.longitude
        }
        
        let maxLat = latitudes.max()!
        let minLat = latitudes.min()!
        let maxLong = longitudes.max()!
        let minLong = longitudes.min()!
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLong + maxLong) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.3,
                                    longitudeDelta: (maxLong - minLong) * 1.3)
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func polyLine() -> [MulticolorPolyline] {
        
        let locations = track.location?.array as! [Location]
        var coordinates: [(CLLocation, CLLocation)] = []
        var speeds: [Double] = []
        var minSpeed = Double.greatestFiniteMagnitude
        var maxSpeed = 0.0
        
        for (first, second) in zip(locations, locations.dropFirst()) {
            let start = CLLocation(latitude: first.latitude, longitude: first.longitude)
            let end = CLLocation(latitude: second.latitude, longitude: second.longitude)
            coordinates.append((start, end))
            
            let distance = end.distance(from: start)
            let time = second.timestamp!.timeIntervalSince(first.timestamp! as Date)
            let speed = time > 0 ? distance / time : 0
            speeds.append(speed)
            minSpeed = min(minSpeed, speed)
            maxSpeed = max(maxSpeed, speed)
        }
        
        var segments: [MulticolorPolyline] = []
        for (start, end) in coordinates {
            let coords = [start.coordinate, end.coordinate]
            let segment = MulticolorPolyline(coordinates: coords, count: 2)
            segment.color = .blue
            segments.append(segment)
        }
        return segments
    }
}
extension TrackDetailsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 3
        return renderer
    }
    
}
