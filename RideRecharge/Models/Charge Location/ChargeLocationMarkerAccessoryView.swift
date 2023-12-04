//
//  ChargeLocationMarkerAccessoryView.swift
//  RideRecharge
//
//  Created by yuri on 21.07.22.
//

import UIKit

class ChargeLocationMarkerAccessoryView: UIView {
    
    static let nibName: String = NSStringFromClass(ChargeLocationMarkerAccessoryView.self)

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var openPlugs: UILabel!
    
    @IBOutlet weak var totalPlugs: UILabel!
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("ChargeLocationMarkerAccessoryView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

}
