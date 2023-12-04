//
//  SendPOIBtn.swift
//  RideRecharge
//
//  Created by yuri on 21.07.22.
//

import UIKit

class SendPOIBtn: UIButton {
    convenience init() {
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "arrow.right.circle")
        
        self.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.configuration = config

    }
}
