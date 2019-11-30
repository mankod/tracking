//
//  FormatDisplay.swift
//  Tracking
//
//  Created by Jose Manuel on 29/11/19.
//  Copyright © 2019 Jose Manuel. All rights reserved.
//

import Foundation

struct FormatDisplay {
  static func distance(_ distance: Double) -> String {
    let distanceMeasurement = Measurement(value: distance, unit: UnitLength.meters)
    return FormatDisplay.distance(distanceMeasurement)
  }
  
  static func distance(_ distance: Measurement<UnitLength>) -> String {
    let formatter = MeasurementFormatter()
    return formatter.string(from: distance)
  }
  
  static func time(_ seconds: Int) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad
    return formatter.string(from: TimeInterval(seconds))!
  }
}

