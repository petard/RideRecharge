//
//  CarDetailsViewController.swift
//  RideRecharge
//
//  Created by yuri on 15.08.22.
//

import UIKit

class CarDetailsViewController: UIViewController, UIViewControllerTransitioningDelegate, UITableViewDelegate, UITableViewDataSource { // 

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var weatherLabel: UILabel!
    @IBOutlet weak var batteryIcon: UIImageView!
    @IBOutlet weak var batteryPercLabel: UILabel!
    @IBOutlet weak var batteryKmLabel: UILabel!
    @IBOutlet weak var fuelPercLabel: UILabel!
    @IBOutlet weak var fuelKmLabel: UILabel!
    @IBOutlet weak var lockedLabel: UIImageView!
    @IBOutlet weak var statusItemsView: UIStackView!
    
    static let storyboardIdentifier: String = String(describing: CarDetailsViewController.self)
    
    private typealias Section = Int
    private typealias ReuseIdentifier = String
    
    private lazy var data: [Section:[ReuseIdentifier]] = [:]
    private lazy var sectionHeader: [Section: String] = [:]
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    
    private func commonInit() {
        modalPresentationStyle = .custom
        transitioningDelegate = self
        isModalInPresentation = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.data = [
            0:[CarStatusTableViewCell.reuseIdentifier, CarFullStatusTableViewCell.reuseIdentifer],
            1:[CarLastTripTableViewCell.reuseIdentifer],
            2:[CarPureTableViewCell.reuseIdentifer,
               CarFuelTableViewCell.reuseIdentifer,
               CarAllTripsTableViewCell.reuseIdentifer],
            3:[CarVOCTableViewCell.reuseIdentifer,
               CarHomeLocationTableViewCell.reuseIdentifer,
               CarTAndCTableViewCell.reuseIdentifer
              ],
        ]
        
        self.sectionHeader = [
            0:"Status",
            1:"Last Trip",
            2:"All Trips",
            3:"Settings"
        ]
        
        User.shared.delegate = self


    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    func updateUsing(vehicle: Vehicle) async {
        await self.updateStatus(for: vehicle)
    }
    
    private enum statusLabels: String {
        case defaultKm = "--km"
        case defaultCelsius = "--C"
        case defaultPerct = "--%"
        case defaultMin = "--min"
        case carLocked = "lock.fill"
        case carUnlocked = "lock.open"
    }
    
    private func setStatusToDefault() {
        self.fuelPercLabel.text = statusLabels.defaultPerct.rawValue
        self.fuelKmLabel.text = statusLabels.defaultKm.rawValue
        self.weatherLabel.text = statusLabels.defaultCelsius.rawValue
        self.batteryPercLabel.text = statusLabels.defaultPerct.rawValue
        self.batteryKmLabel.text = statusLabels.defaultKm.rawValue
        self.batteryIcon.tintColor = .label
    }

    
    private func updateStatus(for vehicle: Vehicle) async {
        guard let status = vehicle.status else {
            self.setStatusToDefault()
            return
        }
                
        // lock status
        self.lockedLabel.image = status.carLocked ? UIImage(systemName: statusLabels.carLocked.rawValue) : UIImage(systemName: statusLabels.carUnlocked.rawValue)
        
        // fuel economy
        self.fuelPercLabel.text = status.fuelAmountLevelInPercent == nil ? statusLabels.defaultPerct.rawValue : "\(status.fuelAmountLevelInPercent!)%"
        self.fuelKmLabel.text = status.fueldistanceToEmpty == nil ? statusLabels.defaultKm.rawValue : "\(status.fueldistanceToEmpty!)km"
        
        // battery and charging status
        let distanceToEmptyKm: String = status.battery?.distanceToEmptyKm == nil ? statusLabels.defaultKm.rawValue : "\(status.battery!.distanceToEmptyKm!)km"
        
        switch status.battery?.chargeStatus {
        case .interrupted:
            self.batteryIcon.tintColor = .systemRed
            self.batteryPercLabel.text = status.battery?.level == nil ? statusLabels.defaultPerct.rawValue : "\(status.battery!.level)%"
            self.batteryKmLabel.text = distanceToEmptyKm
        case .started, .progress, .inserted:
            self.batteryIcon.tintColor = .systemOrange
            self.batteryPercLabel.text = status.battery?.fullyChargedAtTime
            self.batteryKmLabel.text = status.battery?.timeToFullyCharged == nil ? statusLabels.defaultMin.rawValue : "\(status.battery!.timeToFullyCharged)min"
        case .unplugged, .finished:
            self.batteryIcon.tintColor = .label
            self.batteryPercLabel.text = status.battery?.level == nil ? statusLabels.defaultPerct.rawValue : "\(status.battery!.level)%"
            self.batteryKmLabel.text = distanceToEmptyKm
        default:
            self.batteryIcon.tintColor = .label
            self.batteryPercLabel.text = status.battery?.level == nil ? statusLabels.defaultPerct.rawValue : "\(status.battery!.level)%"
            self.batteryKmLabel.text = distanceToEmptyKm
        }
        
        //weather
        let weather = try? await WeatherService.OpenMeteo.current(location: vehicle.coordinate)
        self.weatherLabel.text = weather?.temperature == nil ? statusLabels.defaultCelsius.rawValue : "\(Int(weather!.temperature!))C"
        
        statusItemsView.layoutIfNeeded()
        
    }

    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        let sheet: UISheetPresentationController = .init(presentedViewController: presented, presenting: presenting)
        
        let distanceToBottomMultiplier: Double = 0.12
        
        sheet.detents = [
            .large(),
            .custom(identifier: .small) { context in
                distanceToBottomMultiplier * context.maximumDetentValue
            }
        ]
        sheet.largestUndimmedDetentIdentifier = .small
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.prefersEdgeAttachedInCompactHeight = true
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        sheet.prefersGrabberVisible = true

        return sheet
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.data.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.data[section]?.count ?? 0
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let reuseIdentifier = self.data[indexPath.section]?[indexPath.row] else {
            fatalError("cartableview")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! CarBaseTableViewCell

        // Configure the cell...
        cell.configure(vehicle: User.shared.vehicle)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionHeader[section]
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
        if let nc = segue.destination as? UINavigationController, let vc = nc.children.first as? SettingsHomeTableViewController {
            vc.delegate = self
        }
        if let nc = segue.destination as? UINavigationController, let vc = nc.children.first as? SettingsAccountTableViewController {
            vc.delegate = self
        }
     
     
    }
    

}

extension CarDetailsViewController: SettingsHomeTableViewControllerDelegate {
    
    func didUpdateHomeLocation() {
        self.tableView.reloadData()
    }
    
}

extension CarDetailsViewController: UserDelegate {
    
    func didUpdateVehicle(user: User) {
        
    }
    
    
    func didUpdate(user: User) {
        self.tableView.reloadData()
    }
    
}

extension CarDetailsViewController: SettingsAccountTableViewControllerDelegate {
    
    func didUpdateVOCAccount() {
        self.tableView.reloadData()
    }
    
}

