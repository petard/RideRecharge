//
//  CarBaseTableViewCell.swift
//  CarRemote
//
//  Created by pluto on 25.12.20.
//

import UIKit
import MapKit

class CarStatusTableViewCell: CarBaseTableViewCell {
    
    static let reuseIdentifier: String = String(describing: CarStatusTableViewCell.self)
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var title2: UILabel!
    
    @IBOutlet weak var title3: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func configure(vehicle: Vehicle?) {
        guard let _ = vehicle?.status else {
            return;
        }
        
    //    let lockStatus: String = vehicle!.status!.doorsAndWindowsLocked ? "All doors and windows closed" : "Door or window open"
        
        var lockStatus: String = "All doors and windows closed"
        if !vehicle!.status!.doors.allLocked {
            lockStatus = "Door open"
        }
        if !vehicle!.status!.windows.allLocked {
            lockStatus = "Window open"
        }
        if !vehicle!.status!.windows.allLocked && !vehicle!.status!.doors.allLocked {
            lockStatus = "Door(s) and window(s) open"
        }

        self.title3.text = lockStatus
        
        if vehicle!.status!.engineRunning {
            self.title?.text = "In Use, Engine Running"
            self.title2?.text = "Car data is not being updated."
            return;
        }
        
        switch vehicle?.status?.battery?.chargeStatusDerived {
        case .fullyCharged:
            self.title?.text = "Fully Charged"
            if let d = vehicle?.status?.battery?.chargeStatusTimestamp {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, h:mm a"
                self.title2.text = "Ended \(formatter.string(from: d))"
            } else {
                self.title2?.text = "Cable Plugged In"
            }
            break;
        case .charging:
            self.title?.text = "Charging"
            if let d = vehicle?.status?.battery?.chargeStatusTimestamp {
                let delta = Date().timeIntervalSince(d)
                self.title2.text = "Cable connected \(delta.format(using: [.day, .hour, .minute])!) ago"
            } else {
                self.title2?.text = "Cable Plugged In"
            }
            break;
        default:
            self.title?.text = "Parked";
            if let d = vehicle?.status?.carLockedDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, h:mm a"
                self.title2.text = "Car locked on \(formatter.string(from: d))"
            } else {
                guard let _ = vehicle!.position else {
                    break;
                }
                let location = CLLocation(latitude: vehicle!.position!.latitude, longitude: vehicle!.position!.longitude)
                CLGeocoder().reverseGeocodeLocation(location) { (placemark, error) in
                    DispatchQueue.main.async {
                        if error != nil {
                            self.title2?.isHidden = true
                        } else {
                            self.title2?.text = placemark?.first?.locality
                        }
                    }
                }}
            break;
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.title3.text = nil
        self.title2.text = nil
        self.title.text = nil

    }
    
}
