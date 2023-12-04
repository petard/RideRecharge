//
//  Vehicle.swift
//  CarRemote
//
//  Created by pluto on 27.10.20.
//

import Foundation
import MapKit

class Vehicle: NSObject, Decodable, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: self.position?.latitude ?? 0, longitude: self.position?.longitude ?? 0)
    }
    
    var title: String? {
        guard let attributes = self.attributes else {
            return nil
        }
        return "Your \(attributes.vehicleType)"
    }
    
    var subtitle: String? {
        guard let attributes = self.attributes else {
            return nil
        }
        return attributes.registrationNumber
        
        
    }
    
    class Status: Decodable {
        
        class TyrePressure: Decodable {
            var frontLeftTyrePressure: String
            var frontRightTyrePressure: String
            var rearLeftTyrePressure: String
            var rearRightTyrePressure: String
        }
        
        class Doors: Decodable {
            
            let tailgateOpen: Bool
            let rearRightDoorOpen: Bool
            let rearLeftDoorOpen: Bool
            let frontRightDoorOpen: Bool
            let frontLeftDoorOpen: Bool
            let hoodOpen: Bool
            let timestamp: String
            
            var allLocked: Bool {
                return !tailgateOpen && !rearRightDoorOpen && !rearLeftDoorOpen && !frontRightDoorOpen && !frontLeftDoorOpen && !hoodOpen
            }
        }
        
        class Windows: Decodable {
            let frontLeftWindowOpen: Bool
            let frontRightWindowOpen: Bool
            let rearLeftWindowOpen: Bool
            let rearRightWindowOpen: Bool
            let timestamp: String
            
            var allLocked: Bool {
                return !frontLeftWindowOpen && !frontRightWindowOpen && !rearLeftWindowOpen && !rearRightWindowOpen
            }
        }
        
        var carLocked: Bool
        var carLockedTimestamp: String?
        var carLockedDate: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = VOC.dateFormat
            formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
            if let _ = self.carLockedTimestamp {
                return formatter.date(from: self.carLockedTimestamp!)
            } else {
                return nil
            }
        }
        
        let fuelAmountLevelInPercent: Int?
        var fuelAmountLevelInPercentLocalized: String {
            return self.fuelAmountLevelInPercent == nil ? "--km" : "\(self.fuelAmountLevelInPercent!)%"
        }
        
        let fuelAmountInLiter: Int?
        var fuelAmountInLiterLocalized: String {
            return self.fuelAmountLevelInPercent == nil ? "--L" : "\(self.fuelAmountInLiter!)%"
        }
        
        let fueldistanceToEmpty: Int?
        let engineRunning: Bool
        let battery: Battery?
        let heater: Heater
        let doors: Doors
        let windows: Windows
        
        // Fluids
        var brakeFluid: String
        var washerFluidLevel: String
        var tyrePressure: TyrePressure
        var tyrePressureLocalized: String {
            let defaultValue: String = "Normal"
            guard
                self.tyrePressure.frontLeftTyrePressure == defaultValue,
                self.tyrePressure.frontRightTyrePressure == defaultValue,
                self.tyrePressure.rearLeftTyrePressure == defaultValue,
                self.tyrePressure.frontRightTyrePressure == defaultValue
            else {
                return "Check required";
            }
            return defaultValue
        }
        
        
        // Mileage
        let averageSpeed: Int?
        var averageSpeedLocalized: String {
            if let _ = averageSpeed {
                let km = Double(self.averageSpeed!)
                return "\(String(format: "%.0f", km))km/h"
            } else {
                return "-"
            }
        }
        
        let odometer: Int
        var odometerLocalized: String {
            let km = Double(self.odometer) / 1000
            return "\(String(format: "%.0f", km))km"
        }
        
        
        var remoteClimatizationStatus: String
        
        var doorsAndWindowsLocked: Bool {
            return doors.allLocked && windows.allLocked
        }
        
        enum RemoteClimatization: String {
            case noCableConnected = "NoCableConnected"
            case charging = "Charging"
        }
        
        enum CodingKeys: String, CodingKey {
            case battery = "hvBattery" // Percent
            case doors, windows
            case brakeFluid, washerFluidLevel, tyrePressure
            case fuelAmountLevelInPercent = "fuelAmountLevel"
            case fuelAmountInLiter = "fuelAmount"
            case fueldistanceToEmpty = "distanceToEmpty" // km
            case carLocked, carLockedTimestamp, engineRunning, heater, remoteClimatizationStatus
            case averageSpeed, odometer
        }
        
        static func load() async throws -> Vehicle.Status {
            
            guard !User.shared.isTestUser else {
                return try JSONDecoder().decode(Vehicle.Status.self, from: Data(TestData.vehicleStatus.utf8))
            }
            
            let data = try await VOC.shared.data(for: URL(string: VOC.shared.baseUrl + "/status")!)
            
            return try JSONDecoder().decode(Vehicle.Status.self, from: data)
        }
        
        static func load(completion: @escaping(Vehicle.Status?, ServiceError?) -> Void) {
            
            guard !User.shared.isTestUser else {
                let position = try! JSONDecoder().decode(Vehicle.Status.self, from: Data(TestData.vehicleStatus.utf8))
                completion(position, nil)
                return
            }
            
            var request = URLRequest(url: URL(string: VOC.shared.baseUrl + "/status")! as URL,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = VOC.shared.requestHeaders
            
            let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                guard let _ = data, let status = try? JSONDecoder().decode(Vehicle.Status.self, from: data!) else {
                    completion(nil, ServiceError(response: response))
                    return
                }
                
                completion(status, nil)
            })
            
            dataTask.resume()
        }
    }
    
    class Position: Decodable {
        @objc dynamic var longitude: Double
        @objc dynamic var latitude: Double
        
        static func load() async throws -> Vehicle.Position {
            
            guard !User.shared.isTestUser else {
                let position = try JSONDecoder().decode(Vehicle.self, from: Data(TestData.vehiclePosition.utf8)).position
                if let _ = position {
                    return position!
                }
                throw ServiceError.unknown
            }
            
            let data = try await VOC.shared.data(for: URL(string: VOC.shared.baseUrl + "/position")!)
            let vehicle = try JSONDecoder().decode(Vehicle.self, from: data)
            if let _ = vehicle.position {
                return vehicle.position!
            } else {
                throw ServiceError.unknown
            }
        }
        
        static func load(completion: @escaping(Vehicle.Position?, ServiceError?) -> Void) {
            
            guard !User.shared.isTestUser else {
                let vehicle = try! JSONDecoder().decode(Vehicle.self, from: Data(TestData.vehiclePosition.utf8))
                completion(vehicle.position, nil)
                return
            }
            
            var request = URLRequest(url: URL(string: VOC.shared.baseUrl + "/position")! as URL,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = VOC.shared.requestHeaders
            
            let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                
                guard let _ = data, let vehicle = try? JSONDecoder().decode(Vehicle.self, from: data!), let position = vehicle.position else {
                    completion(nil, ServiceError(response: response))
                    return;
                }
                
                completion(position, nil)
            })
            
            dataTask.resume()
        }
    }
    
    class Heater: Decodable {
        var status: Status
        var timestamp: String
        
        var isEnabled: Bool {
            return self.status == .off ? false : true
        }
        
        enum Status: String, Decodable {
            case on = "on"
            case off = "off"
        }
    }
    
    class Battery: Decodable {
        let level: Int
        let distanceToEmptyKm: Int?
        let chargeStatus: ChargeStatus?
        let timeToFullyCharged: Int // Min
        let timeToFullyChargedStarted: String
        let chargeStatusDerived: ChargeStatusDerived?
        let hvBatteryChargeStatusTimestamp: String
        
        var chargingCompleted: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = VOC.dateFormat
            formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
            return formatter.date(from: self.timeToFullyChargedStarted)?.addingTimeInterval(Double(self.timeToFullyCharged)*60)
        }
        
        var fullyChargedAtDate: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = VOC.dateFormat
            formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
            return formatter.date(from: self.timeToFullyChargedStarted)?.addingTimeInterval(Double(self.timeToFullyCharged)*60)
        }
        
        var fullyChargedAtTime: String? {
            let formatter = DateFormatter()
            formatter.dateFormat = "hh:mm"
            formatter.timeZone = NSTimeZone.local
            if let _ = self.fullyChargedAtDate {
                return formatter.string(from: self.fullyChargedAtDate!)
            } else {
                return nil
            }
        }
        
        var fullyChargedAtDay: String? {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            formatter.timeZone = NSTimeZone.local
            if let _ = self.fullyChargedAtDate {
                return formatter.string(from: self.fullyChargedAtDate!)
            } else {
                return nil
            }
        }
        
        var chargeStatusTimestamp: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = VOC.dateFormat
            formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
            if let _ = self.fullyChargedAtDate {
                return formatter.date(from: self.hvBatteryChargeStatusTimestamp)
            } else {
                return nil
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case level = "hvBatteryLevel" // Percent
            case distanceToEmptyKm = "distanceToHVBatteryEmpty" // km
            case chargeStatus = "hvBatteryChargeStatus"
            case timeToFullyCharged = "timeToHVBatteryFullyCharged" // min
            case timeToFullyChargedStarted = "timeToHVBatteryFullyChargedTimestamp" // UTC "2020-11-04T12:03:13+0000",
            case chargeStatusDerived = "hvBatteryChargeStatusDerived"
            case hvBatteryChargeStatusTimestamp
        }
        
        enum ChargeStatus: String, Decodable {
            case progress = "ChargeProgress"
            case started = "Started"
            case interrupted = "Interrupted"
            case unplugged = "PlugRemoved"
            case finished = "ChargeEnd"
            case inserted = "PlugInserted"
        }
        
        enum ChargeStatusDerived: String, Decodable {
            case fullyCharged = "CablePluggedInCar_FullyCharged"
            case chargingPaused = "CablePluggedInCar_ChargingPaused"
            case charging = "CablePluggedInCar_Charging"
            case notPlugged = "CableNotPluggedInCar"
            case chargingInterrupted = "CablePluggedInCar_ChargingInterrupted"
        }
    }
    
    init(attributes: Attributes, status: Status, position: Vehicle.Position) {
        self.attributes = attributes
        self.status = status
        self.position = position
    }
    
    
    var attributes: Attributes?
    
    var status: Status?
    
    var position: Position?
    
    var journal: DriveJournal?
    
    private enum CodingKeys: String, CodingKey {
        case position
    }
    
    class Attributes: Decodable {
        let vehicleType: String
        let modelYear: Int
        let registrationNumber: String
        let assistanceCallSupported: Bool
        let bCallAssistanceNumber: String
        let unlockSupported: Bool
        let lockSupported: Bool
        let VIN: String
        let sendPOIToVehicleVersionsSupported: [String]
        let preclimatizationSupported: Bool
        let remoteHeaterSupported: Bool
        let subscriptionEndDate: String
        
        // Codes
        let engineCode: String
        let exteriorCode: String
        let interiorCode: String
        let tyreDimensionCode: String
        let vehicleTypeCode: String
        let gearboxCode: String
        let vehiclePlatform: String
        
        private var subscriptionEnd: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = VOC.dateFormat
            formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
            return formatter.date(from: self.subscriptionEndDate)
        }
        
        var VOCsubscriptionEnd: String? {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            formatter.timeZone = NSTimeZone.local
            if let _ = self.subscriptionEnd {
                return formatter.string(from: self.subscriptionEnd!)
            } else {
                return nil
            }
        }
        
        static func load() async throws -> Vehicle.Attributes {
            return try await Vehicle.Attributes.load(service: VOC.shared)
        }

        static func load(completion: @escaping(Vehicle.Attributes?, ServiceError?) -> Void) {
            Vehicle.Attributes.load(service: VOC.shared) { (attributes, error) in
                completion(attributes, error)
            }
        }
        
        static func load(service: VOC) async throws -> Vehicle.Attributes {
            
            guard !User.shared.isTestUser else {
                let attributes = try JSONDecoder().decode(Vehicle.Attributes.self, from: Data(TestData.vehicleAttributes.utf8))
                return attributes
            }
            
            let data = try await VOC.shared.data(for: URL(string: VOC.shared.baseUrl + "/attributes")!)

            return try JSONDecoder().decode(Vehicle.Attributes.self, from: data)
 
        }

        
        static func load(service: VOC, completion: @escaping(Vehicle.Attributes?, ServiceError?) -> Void) {
            
            guard !User.shared.isTestUser else {
                let attributes = try! JSONDecoder().decode(Vehicle.Attributes.self, from: Data(TestData.vehicleAttributes.utf8))
                completion(attributes, nil)
                return
            }
            
            var request = URLRequest(url: URL(string: service.baseUrl + "/attributes")! as URL,
                                     cachePolicy: .returnCacheDataElseLoad,
                                     timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = service.requestHeaders
            
            let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                guard
                    let _ = data,
                    let attributes = try? JSONDecoder().decode(Vehicle.Attributes.self, from: data!)
                else {
                    print("Vehicle.Attributes.LoadingError:", error ?? "")
                    completion(nil, ServiceError(response: response))
                    return;
                }
                
                completion(attributes, nil)
                
            })
            
            dataTask.resume()
        }
        
    }

    
    class DriveJournal: Decodable {
        class Trip: Decodable {
            
            class Details: Decodable {
                var fuelConsumption: Int? // Can be null in server JSON
                var electricalConsumption: Int? // Can be null in server JSON
                var electricalRegeneration: Int?
                var distance: Int
                var startTime: String
                var endTime: String
                
                var startDate: Date? {
                    let formatter = DateFormatter()
                    formatter.dateFormat = VOC.dateFormat
                    formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    return formatter.date(from: self.startTime)
                }
                
                var endDate: Date? {
                    let formatter = DateFormatter()
                    formatter.dateFormat = VOC.dateFormat
                    formatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
                    return formatter.date(from: self.endTime)
                }
                
                var isPureTrip: Bool {
                    return (self.fuelConsumption == 0 || self.fuelConsumption == nil) && self.electricalConsumption != nil
                }
                
            }
            
            var id: Int
            var tripDetails: [Trip.Details]
            var detail: Trip.Details? {
                return self.tripDetails.first
            }
            
            func delete(completion: @escaping(ServiceError?) -> Void) {
                let url = URL(string: "\(VOC.shared.baseUrl)/trips/\(self.id)")!
                var request = URLRequest(url:  url,
                                         cachePolicy: .useProtocolCachePolicy,
                                         timeoutInterval: 10.0)
                request.httpMethod = "DELETE"
                request.allHTTPHeaderFields = VOC.shared.requestHeaders
                
                let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                    if error != nil {
                        completion(ServiceError(response: response))
                    } else {
                        completion(nil)
                    }
                })
                
                dataTask.resume()
            }
            
        }
        
        var trips: [Trip]
                
        var pureConsumption: Int {
            return trips.reduce(0, { sum, trip in
                return trip.detail?.isPureTrip == true ? sum + trip.detail!.electricalConsumption! : 0
            })
        }
        
        var pureDistance: Int { // Meter
            return trips.reduce(0, { sum, trip in
                return trip.detail?.isPureTrip == true ? sum + trip.detail!.distance : 0
            })
        }
        
        var pureTrips: Int {
            return self.trips.filter({ trip in
                return trip.detail?.isPureTrip == true
            }).count
        }
        
        static func load() async throws -> Vehicle.DriveJournal {
            
            guard !User.shared.isTestUser else {
                return try JSONDecoder().decode(Vehicle.DriveJournal.self, from: Data(TestData.vehicleDriveJournal.utf8))
            }
            
            let data = try await VOC.shared.data(for: URL(string: VOC.shared.baseUrl + "/trips")!)
            return try JSONDecoder().decode(Vehicle.DriveJournal.self, from: data)
        }

        
        static func load(completion: @escaping(Vehicle.DriveJournal?, ServiceError?) -> Void) {
            
            guard !User.shared.isTestUser else {
                let trips = try! JSONDecoder().decode(Vehicle.DriveJournal.self, from: Data(TestData.vehicleDriveJournal.utf8))
                completion(trips, nil)
                return
            }
            
            var request = URLRequest(url: URL(string: VOC.shared.baseUrl + "/trips")! as URL,
                                     cachePolicy: .useProtocolCachePolicy,
                                     timeoutInterval: 10.0)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = VOC.shared.requestHeaders
            
            let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                guard
                    let _ = data,
                    let trips = try? JSONDecoder().decode(Vehicle.DriveJournal.self, from: data!)
                else {
                    print("Vehicle.Trips.LoadingError:", error ?? "")
                    completion(nil, ServiceError(response: response))
                    return;
                }
                
                completion(trips, nil)
                
            })
            
            dataTask.resume()
        }
    }
    
    override init() {
        super.init()
    }
    
    class func load() async throws -> Vehicle {
        
        let v = Vehicle()
        
        async let position = try Vehicle.Position.load()
        async let status = try Vehicle.Status.load()
        async let attributes = try Vehicle.Attributes.load()
        
        v.position = try? await position
        v.attributes = try? await attributes
        v.status = try await status

        return v
    }
    
}
