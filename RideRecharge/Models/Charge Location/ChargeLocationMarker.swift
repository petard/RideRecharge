//
//  ChargeLocationMarker.swift
//  RideRecharge
//
//  Created by yuri on 21.07.22.
//

import Foundation
import UIKit
import MapKit

private let multiChargeLocationClusterID = "multiChargeLocation"

class ChargeLocationMarker: MKMarkerAnnotationView {
    
    static let reuseIdentifier: String = NSStringFromClass(ChargeLocationMarker.self)
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    private func commonInit() {
        self.animatesWhenAdded = false
        self.canShowCallout = true
        self.displayPriority = .required
        self.titleVisibility = .hidden
        self.clusteringIdentifier = multiChargeLocationClusterID
    }
    
    func set(location: ChargeLocation) {
        self.glyphImage = UIImage(systemName: "bolt.fill") // somehow glyp is not retained when set in init

        let accessory = ChargeLocationMarkerAccessoryView(frame: CGRect(x: 0, y: 0, width: 50, height: 40))
        accessory.openPlugs.text = "\(location.availableChargePoints)"
        accessory.totalPlugs.text = "\(location.numberOfChargePoints)"
        self.leftCalloutAccessoryView = accessory
                        
        switch location.availability {
        case .available:
            self.markerTintColor = UIColor.systemGreen
            self.alpha = 1
            
            if
                location.numberOfChargePoints > 1,
                location.availableChargePoints == 1
            {
                self.markerTintColor = UIColor.systemOrange
            }

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
        self.commonInit()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.annotation = nil
    }
    
}


