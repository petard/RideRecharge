//
//  CarBaseTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit

class CarTAndCTableViewCell: CarBaseTableViewCell {
    
    static let reuseIdentifer: String = String(describing: CarTAndCTableViewCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func configure(vehicle: Vehicle?) {
        // Func to be overriden by subclasses
    }

}
