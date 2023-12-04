//
//  VehicleMarker.swift
//  RideRecharge
//
//  Created by yuri on 25.07.22.
//

import Foundation
import MapKit

// Helper classes and methods

class VehicleMarker: MKMarkerAnnotationView {
    
    static let reuseIdentifier: String = NSStringFromClass(Vehicle.self)
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.animatesWhenAdded = false
        self.canShowCallout = true
        self.displayPriority = .required
    }
    
    func set(vehicle: Vehicle) {
        self.glyphImage = UIImage(systemName: "car")

        if vehicle.status?.battery?.chargeStatusDerived == .charging {
            self.markerTintColor = UIColor.systemOrange
        } else {
            self.markerTintColor = UIColor.systemBlue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
