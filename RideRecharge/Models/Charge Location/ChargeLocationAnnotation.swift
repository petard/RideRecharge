//
//  ChargeLocationAnnotation.swift
//  RideRecharge
//
//  Created by yuri on 27.07.22.
//

import MapKit

class ChargeLocationAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var location: CLLocation {
        get {
            return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }
    
    init(location: ChargeLocation) {
        self.coordinate = location.coordinate
        super.init()
        self.title = location.postalAddress
        self.subtitle = location.locationOperator
    }
}
