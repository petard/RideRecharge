//
//  CarBaseTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit

class CarFullStatusTableViewCell: CarBaseTableViewCell {
    
    static let reuseIdentifer: String = String(describing: CarFullStatusTableViewCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func configure(vehicle: Vehicle?) {
        // Func to be overriden by subclasses
    }

}
