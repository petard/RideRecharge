//
//  CarFullStatusTableViewController.swift
//  RideRecharge
//
//  Created by pluto on 10.01.21.
//

import UIKit

class CarFullStatusTableViewController: UITableViewController {

    @IBAction func closeBarBtn(_ sender: Any) {
        self.dismiss(animated: true)
    }
    // Mileage
    @IBOutlet weak var totalDistance: UILabel!
    @IBOutlet weak var averageSpeed: UILabel!
    
    // Liquids and Air
    @IBOutlet weak var fuelLiter: UILabel!
    @IBOutlet weak var fuelPerc: UILabel!
    @IBOutlet weak var brakeFluids: UILabel!
    @IBOutlet weak var washerFluids: UILabel!
    @IBOutlet weak var tyrePressure: UILabel!
    
    // Doors and Windows
    @IBOutlet weak var tailGate: UILabel!
    @IBOutlet weak var rearDoors: UILabel!
    @IBOutlet weak var frontDoors: UILabel!
    @IBOutlet weak var frontWindows: UILabel!
    @IBOutlet weak var rearWindows: UILabel!
    @IBOutlet weak var hood: UILabel!
    
    // Vehicle Codes
    @IBOutlet weak var modelType: UILabel!
    @IBOutlet weak var modelYear: UILabel!
    @IBOutlet weak var vehicleType: UILabel!
    @IBOutlet weak var registrationNumber: UILabel!
    @IBOutlet weak var engineCode: UILabel!
    @IBOutlet weak var gearBoxCode: UILabel!
    @IBOutlet weak var vehiclePlatform: UILabel!
    @IBOutlet weak var interiorCode: UILabel!
    @IBOutlet weak var exteriorCode: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    private func doorState(value: Bool?) -> String {
        guard let _ = value else {
            return "--";
        }
        return value! ? "Open" : "Closed"
        
    }
    
    private func setDoorWindowState() {

        enum State: String {
            case open = "Open"
            case closed = "Closed"
            case unknown = "--"
            
            init(value: Bool?) {
                if let _ = value {
                    self = value! ? .open : .closed
                } else {
                    self = .unknown
                }
            }

        }

        // Doors & Windows
        
        self.tailGate.text = State(value: User.shared.vehicle?.status?.doors.tailgateOpen).rawValue
        self.hood.text = State(value: User.shared.vehicle?.status?.doors.hoodOpen).rawValue

        if
            State(value: User.shared.vehicle?.status?.doors.rearLeftDoorOpen) == .closed,
            State(value: User.shared.vehicle?.status?.doors.rearRightDoorOpen) == .closed {
            self.rearDoors.text = State.closed.rawValue
        }
        if
            State(value: User.shared.vehicle?.status?.doors.frontLeftDoorOpen) == .closed,
            State(value: User.shared.vehicle?.status?.doors.frontRightDoorOpen) == .closed {
            self.frontDoors.text = State.closed.rawValue
        }
        if
            State(value: User.shared.vehicle?.status?.windows.rearLeftWindowOpen) == .closed,
            State(value: User.shared.vehicle?.status?.windows.rearRightWindowOpen) == .closed {
            self.rearWindows.text = State.closed.rawValue
        }
        if
            State(value: User.shared.vehicle?.status?.windows.frontLeftWindowOpen) == .closed,
            State(value: User.shared.vehicle?.status?.windows.frontRightWindowOpen) == .closed {
            self.frontWindows.text = State.closed.rawValue
        }
        

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Mileage
        let defaultValue: String = "--"
        self.totalDistance.text = User.shared.vehicle?.status?.odometerLocalized ?? defaultValue
        self.averageSpeed.text = User.shared.vehicle?.status?.averageSpeedLocalized ?? defaultValue

        // Liquids and Air
        self.fuelLiter.text = User.shared.vehicle?.status?.fuelAmountInLiterLocalized ?? defaultValue
        self.fuelPerc.text = User.shared.vehicle?.status?.fuelAmountLevelInPercentLocalized ?? defaultValue
        self.brakeFluids.text = User.shared.vehicle?.status?.brakeFluid ?? defaultValue
        self.washerFluids.text = User.shared.vehicle?.status?.washerFluidLevel ?? defaultValue
        self.tyrePressure.text = User.shared.vehicle?.status?.tyrePressureLocalized ?? defaultValue

        // Doors
        self.setDoorWindowState()

        // Vehicle Codes
        self.modelType.text = User.shared.vehicle?.attributes?.vehicleType ?? defaultValue
        self.modelYear.text = "\(User.shared.vehicle?.attributes?.modelYear ?? 0)"
        self.vehicleType.text = User.shared.vehicle?.attributes?.vehicleTypeCode ?? defaultValue
        self.registrationNumber.text = User.shared.vehicle?.attributes?.registrationNumber ?? defaultValue
        self.engineCode.text = User.shared.vehicle?.attributes?.engineCode ?? defaultValue
        self.gearBoxCode.text = User.shared.vehicle?.attributes?.gearboxCode ?? defaultValue
        self.vehiclePlatform.text = User.shared.vehicle?.attributes?.vehiclePlatform ?? defaultValue
        self.interiorCode.text = User.shared.vehicle?.attributes?.interiorCode ?? defaultValue
        self.exteriorCode.text = User.shared.vehicle?.attributes?.exteriorCode ?? defaultValue
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
