//
//  CarBaseTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit

class CarFuelTableViewCell: CarBaseTableViewCell {
    
    @IBOutlet weak var title1: UILabel!
    @IBOutlet weak var title2: UILabel!
    @IBOutlet weak var title3: UILabel!
    
    
    static let reuseIdentifer: String = String(describing: CarFuelTableViewCell.self)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func configure(vehicle: Vehicle?) {
        guard let _ = vehicle?.journal?.trips else {
            return;
        }
        
        self.title1.text = "\(EnergyEconomy.totalDistance(trips: vehicle!.journal!.trips)/1000)km"
        let deciliter = EnergyEconomy.per100km(distance: EnergyEconomy.totalDistance(trips: vehicle!.journal!.trips), energy: EnergyEconomy.totalFuelConsumption(trips: vehicle!.journal!.trips))
        self.title2.text = "\(String(format: "%.0f", deciliter*10))L/100km"
        let fuelShare: Double = 1-(Double(EnergyEconomy.totalPureDistance(trips: vehicle!.journal!.trips)) / Double(EnergyEconomy.totalDistance(trips: vehicle!.journal!.trips)))
        self.title3.text = "\(String(format: "%.0f", fuelShare*100))%"

    }

}
