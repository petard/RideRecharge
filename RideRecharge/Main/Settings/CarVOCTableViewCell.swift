//
//  CarBaseTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit

class CarVOCTableViewCell: CarBaseTableViewCell {
    
    static let reuseIdentifer: String = String(describing: CarVOCTableViewCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        // Initialization code
        var content = self.defaultContentConfiguration()

        // Configure content.
        content.image = UIImage(systemName: "person.circle")
        content.text =  "Volvo On Call Account"
        content.secondaryText = VOC.shared.volvoid

        self.contentConfiguration = content

    }

    override func configure(vehicle: Vehicle?) {
        // Func to be overriden by subclasses
    }

}
