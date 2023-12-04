//
//  VehicleSelectionTableViewController.swift
//  RideRecharge
//
//  Created by pluto on 13.02.21.
//

import UIKit

class VehicleSelectionTableViewController: UITableViewController {
    
    public var vehicleIds: [String]?
    
    public var username: String?
    
    public var password: String?
    
    private lazy var vehicles: [Vehicle.Attributes] = []
    
    public var selectedVehicleId: String?
    
    private let vehicleCellReuseIdentifier: String = "vehicleIdentifier"
    
    private static let unwindSelfSegue = "unwindSelf"

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let _ = self.vehicleIds, let _ = self.username, let _ = self.password else {
            return;
        }
        
        let group = DispatchGroup()
        
        for vehicleId in self.vehicleIds! {
            group.enter()
            let voc = VOC(volvoid: self.username!, password: self.password!, vin: vehicleId)
            Vehicle.Attributes.load(service: voc) { [weak self] (attributes, error) in
                if let _ = attributes {
                    self?.vehicles.append(attributes!)
                }
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.global()) {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.vehicles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.vehicleCellReuseIdentifier, for: indexPath)

        cell.textLabel?.text = "\(self.vehicles[indexPath.row].vehicleType) \(self.vehicles[indexPath.row].registrationNumber)"
        cell.detailTextLabel?.text = self.vehicles[indexPath.row].VIN
        
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedVehicleId = self.vehicleIds![indexPath.row]
        self.performSegue(withIdentifier: VehicleSelectionTableViewController.unwindSelfSegue, sender: nil)
    }

}
