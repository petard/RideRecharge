//
//  CarTableViewController.swift
//  CarRemote
//
//  Created by pluto on 24.12.20.
//

import UIKit

class CarTripTableViewController: UITableViewController {
    
    private typealias Section = Int
    private typealias ReuseIdentifier = String
    
    @IBAction func cancelBarBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    private lazy var orderedSections: [Date] = []
    private lazy var tripsByDate: [Date: [Vehicle.DriveJournal.Trip]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func groupData() {
        guard let trips = User.shared.vehicle?.journal?.trips else {
            return;
        }
        // Group Trips
        let empty: [Date: [Vehicle.DriveJournal.Trip]] = [:]
        self.tripsByDate = trips.reduce(into: empty) { (acc, cur) in
            let components = Calendar.current.dateComponents([.year, .month, .day], from: cur.detail!.endDate!)
            let date = Calendar.current.date(from: components)!
            let existing = acc[date] ?? []
            acc[date] = existing + [cur]
        }
        self.orderedSections = Array(self.tripsByDate.keys).sorted(by: { $0.compare($1) == .orderedDescending }) // order by date desc
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.groupData()
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.orderedSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionDate = self.orderedSections[section]
        return self.tripsByDate[sectionDate]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionDate = self.orderedSections[indexPath.section]
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: CarTripTableViewCell.reuseIdentifer, for: indexPath) as? CarTripTableViewCell,
            let trip = self.tripsByDate[sectionDate]?[indexPath.row]
        else {
            fatalError("CarTripTableViewController cellForRowAt")
        }
        
        // Configure the cell...
        cell.configure(trip: trip)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let sectionDate = self.orderedSections[indexPath.section]
        if editingStyle == .delete {
            let trip = self.tripsByDate[sectionDate]?[indexPath.row]
            trip?.delete(completion: { (error) in
                DispatchQueue.main.async {
                    if error != nil {
                        Toast.popError(message: error!.localizedDescription, controller: self.parent)
                    } else {
                        self.tripsByDate[sectionDate]!.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                    }
                }
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let sectionDate = self.orderedSections[section]
        return formatter.string(from: sectionDate)
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

extension Array where Element: Hashable {
    var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}
