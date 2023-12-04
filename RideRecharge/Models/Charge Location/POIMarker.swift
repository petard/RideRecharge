//
//  ChargeLocationMarker.swift
//  RideRecharge
//
//  Created by yuri on 21.07.22.
//

import Foundation
import UIKit
import MapKit

class POIMarker: MKMarkerAnnotationView {
    
    static let reuseIdentifier: String = NSStringFromClass(POIMarker.self)
        
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.animatesWhenAdded = false
        self.canShowCallout = true
        self.markerTintColor = UIColor.systemTeal
        self.displayPriority = .required
    }
    
    func set(location: ChargeLocation) {
        switch location.availability {
        case .available:
            self.markerTintColor = UIColor.systemGreen
            self.alpha = 1
            break;
        case .occupied:
            self.markerTintColor = UIColor.systemRed
            self.alpha = 0.4
            break;
        case .unkown, .offline:
            self.markerTintColor = UIColor.systemGray
            self.alpha = 0.4
            break;
        }

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
