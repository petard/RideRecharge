//
//  CarBaseTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit

class CarLastTripTableViewCell: CarBaseTableViewCell {
    
    static let reuseIdentifer: String = String(describing: CarLastTripTableViewCell.self)
    
    @IBOutlet weak var title1: UILabel!
    @IBOutlet weak var title2: UILabel!
    @IBOutlet weak var title3: UILabel!
    @IBOutlet weak var tripImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func configure(vehicle: Vehicle?) {
        guard let _ = vehicle else {
            return
        }
        guard
            let distance = vehicle?.journal?.trips.first?.detail?.distance,
            let startDate = vehicle?.journal?.trips.first?.detail?.startDate,
            let endDate = vehicle?.journal?.trips.first?.detail?.endDate
        else {
            return
        }

        let kilometers: Double = Double(distance) / 1000
        let delta = endDate.timeIntervalSince(startDate)

        self.title1.text = "\(delta.format(using: [.hour, .minute, .second])!)"
        self.title2.text = "\(String(format: "%.0f", kilometers))km"
        guard
            let lastTrip = vehicle?.journal?.trips.first,
            let _ = lastTrip.detail
        else {
            return;
        }
        
        self.title3.text = "-- Consumption"

        if let _ = lastTrip.detail?.fuelConsumption {
            self.tripImage.image = UIImage(systemName: "drop.fill")
            self.tripImage.tintColor = .systemBlue
            let deciliterfuel = EnergyEconomy.per100km(distance: EnergyEconomy.totalDistance(trips: [lastTrip]), energy: EnergyEconomy.totalFuelConsumption(trips: [lastTrip])) * 10 // since fuel is  in dc
            self.title3.text = "\(String(format: "%.1f", deciliterfuel))l/100km Consumption"
        }
        
        if lastTrip.detail!.isPureTrip {
            self.title3.text = "-- kWh/100km"
            self.tripImage.image = UIImage(systemName: "bolt.fill")
            self.tripImage.tintColor = .systemOrange
            if let _ = lastTrip.detail?.electricalConsumption {
                let kWh = EnergyEconomy.per100km(distance: EnergyEconomy.totalPureDistance(trips: [lastTrip]), energy: EnergyEconomy.totalPureElectricalConsumption(trips: [lastTrip]))
                self.title3.text = "\(String(format: "%.1f", kWh))kWh/100km Consumption"
            }
        }
        
    }

}

extension TimeInterval {
    func format(using units: NSCalendar.Unit) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll

        return formatter.string(from: self)
    }
}
