//
//  CarBaseTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit

class CarHomeLocationTableViewCell: CarBaseTableViewCell {
    
    static let reuseIdentifer: String = String(describing: CarHomeLocationTableViewCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.update()
    }
    
    func update() {
        var content = self.defaultContentConfiguration()

        // Configure content.
        content.image = UIImage(systemName: "house")
        content.text =  "Home Location"
        content.secondaryText = User.shared.home?.subtitle

        self.contentConfiguration = content

    }

    override func configure(vehicle: Vehicle?) {
        // Func to be overriden by subclasses
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        var content = self.defaultContentConfiguration()

        // Configure content.
        content.image = UIImage(systemName: "house")
        content.text =  "Home Location"
        content.secondaryText = User.shared.home?.subtitle

        self.contentConfiguration = content
    }

}
