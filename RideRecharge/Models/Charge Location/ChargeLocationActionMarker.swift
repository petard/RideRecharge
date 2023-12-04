//
//  ChargeLocationActionMarker.swift
//  RideRecharge
//
//  Created by yuri on 21.09.22.
//

import Foundation
import MapKit

class ChargeLocationActionMarker: ChargeLocationMarker {
    
    private let sendBtn: SendPOIBtn = SendPOIBtn()
    
    var isSending: Bool = false {
        didSet {
            if isSending {
                self.sendBtn.configuration?.showsActivityIndicator = true
                self.sendBtn.isUserInteractionEnabled = false
            } else {
                self.sendBtn.configuration?.showsActivityIndicator = false
                self.sendBtn.isUserInteractionEnabled = true
            }
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.rightCalloutAccessoryView = sendBtn
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.rightCalloutAccessoryView = sendBtn
    }

}
