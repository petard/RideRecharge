//
//  CarBaseTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit

class CarPureTableViewCell: CarBaseTableViewCell {
    
    static let reuseIdentifer: String = String(describing: CarPureTableViewCell.self)
    
    @IBOutlet weak var title1: UILabel!
    @IBOutlet weak var title2: UILabel!
    @IBOutlet weak var title3: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func configure(vehicle: Vehicle?) {
        guard let _ = vehicle?.journal else {
            return
        }
        self.title1.text = "\(EnergyEconomy.totalPureDistance(trips: vehicle!.journal!.trips)/1000)km"
        let kWh = EnergyEconomy.per100km(distance: EnergyEconomy.totalPureDistance(trips: vehicle!.journal!.trips), energy: EnergyEconomy.totalPureElectricalConsumption(trips: vehicle!.journal!.trips))
        self.title2.text = "\(String(format: "%.0f", kWh))kWh/100km"
        let pureShare: Double = Double(EnergyEconomy.totalPureDistance(trips: vehicle!.journal!.trips)) / Double(EnergyEconomy.totalDistance(trips: vehicle!.journal!.trips))
        self.title3.text = "\(String(format: "%.0f", pureShare*100))%"
    }
    
     func configureNew(vehicle: Vehicle?) {
        guard let _ = vehicle?.journal else {
            return
        }
        self.title1.text = "\(vehicle!.journal!.pureDistance/1000)km"
        var m: Int = 0
        for trip in vehicle!.journal!.trips {
            //print(trip.detail!.fuelConsumption)
            //print(trip.detail!.isPureTrip)
            if trip.detail!.isPureTrip {
                m += trip.detail!.distance
            }
        }
        print("dist", m)
        let kWh = (vehicle!.journal!.pureConsumption / (vehicle!.journal!.pureDistance*1000))*100
        self.title2.text = "\(String(format: "%.0f", kWh))kWh/100km"
        let pureShare: Double = Double(EnergyEconomy.totalPureDistance(trips: vehicle!.journal!.trips)) / Double(EnergyEconomy.totalDistance(trips: vehicle!.journal!.trips))
        self.title3.text = "\(String(format: "%.0f", pureShare*100))%"
    }
/*
 override func configure(vehicle: Vehicle?) {
     guard let _ = vehicle?.journal else {
         return
     }
     self.title1.text = "\(EnergyEconomy.totalPureDistance(trips: vehicle!.journal!.trips)/1000)km"
     let kWh = EnergyEconomy.per100km(distance: EnergyEconomy.totalPureDistance(trips: vehicle!.journal!.trips), energy: EnergyEconomy.totalPureElectricalConsumption(trips: vehicle!.journal!.trips))
     self.title2.text = "\(String(format: "%.0f", kWh))kWh/100km"
     let pureShare: Double = Double(EnergyEconomy.totalPureDistance(trips: vehicle!.journal!.trips)) / Double(EnergyEconomy.totalDistance(trips: vehicle!.journal!.trips))
     self.title3.text = "\(String(format: "%.0f", pureShare*100))%"
 }

 */
}
