//
//  CarTableViewController.swift
//  CarRemote
//
//  Created by pluto on 24.12.20.
//

import UIKit

class CarTableViewController: UITableViewController {
    
    private typealias Section = Int
    private typealias ReuseIdentifier = String
        
    private lazy var data: [Section:[ReuseIdentifier]] = [:]
    private lazy var sectionHeader: [Section: String] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.data = [
            0:[CarStatusTableViewCell.reuseIdentifier, CarFullStatusTableViewCell.reuseIdentifer],
            1:[CarLastTripTableViewCell.reuseIdentifer],
            2:[CarPureTableViewCell.reuseIdentifer,
               CarFuelTableViewCell.reuseIdentifer,
               CarAllTripsTableViewCell.reuseIdentifer],
        ]
        
        self.sectionHeader = [
            0:"Status",
            1:"Last Trip",
            2:"All Trips",
        ]
        
        User.shared.delegate = self
        
    }

    private func update() {
        Task {
            User.shared.vehicle?.journal = try? await Vehicle.DriveJournal.load()
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.data[section]?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let reuseIdentifier = self.data[indexPath.section]?[indexPath.row] else {
            fatalError("catableview")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! CarBaseTableViewCell

        // Configure the cell...
        cell.configure(vehicle: User.shared.vehicle)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionHeader[section]
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CarTableViewController: UserDelegate {
    func didUpdate(user: User) {
        self.update()
    }
    
    func didUpdateVehicle(user: User) {
        self.update()
    }
}


