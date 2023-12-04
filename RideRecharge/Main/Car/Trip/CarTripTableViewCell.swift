//
//  CarTripTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit

class CarTripTableViewCell: UITableViewCell {
    
    static let reuseIdentifer: String = String(describing: CarTripTableViewCell.self)
    
    @IBOutlet weak var info1: UILabel!
    @IBOutlet weak var info2: UILabel!
    @IBOutlet weak var info3: UILabel!
    @IBOutlet weak var consumption: UILabel!
    @IBOutlet weak var tripType: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    private func isToday(date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date) == formatter.string(from: Date())
    }
    
    func configure(trip: Vehicle.DriveJournal.Trip) {
        
        guard
            let distance = trip.detail?.distance,
            let startDate = trip.detail?.startDate,
            let endDate = trip.detail?.endDate
        else {
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        self.info1.text = formatter.string(from: endDate)

        let kilometers: Double = Double(distance) / 1000
        let delta = endDate.timeIntervalSince(startDate)

        self.info2.text = "\(delta.format(using: [.hour, .minute])!)"
        if kilometers < 10 {
            self.info3.text = "\(String(format: "%.1f", kilometers))km"
        } else {
            self.info3.text = "\(String(format: "%.0f", kilometers))km"
        }
        // Consumption
        if let _ = trip.detail?.isPureTrip, trip.detail!.isPureTrip {
            
            self.tripType.image = UIImage(systemName: "bolt.fill")
            self.tripType.tintColor = .systemOrange
            
            if let _ = trip.detail?.electricalConsumption {
                let kWh = EnergyEconomy.per100km(distance: EnergyEconomy.totalPureDistance(trips: [trip]), energy: EnergyEconomy.totalPureElectricalConsumption(trips: [trip]))
                self.consumption.text = "\(String(format: "%.1f", kWh))kWh"
            } else {
                self.consumption.text = "--"
            }
        } else {
            if let _ = trip.detail?.fuelConsumption {
                self.tripType.image = UIImage(systemName: "drop.fill")
                self.tripType.tintColor = .systemBlue
                let deciliterfuel = EnergyEconomy.per100km(distance: EnergyEconomy.totalDistance(trips: [trip]), energy: EnergyEconomy.totalFuelConsumption(trips: [trip])) * 10 // since fuel is  in dc
                self.consumption.text = "\(String(format: "%.1f", deciliterfuel))l"
            } else {
                self.tripType.image = nil
                self.consumption.text = "--"
            }
        }

    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.info1.text = nil
        self.info2.text = nil
        self.info3.text = nil
        self.consumption.text = nil
    }

}
