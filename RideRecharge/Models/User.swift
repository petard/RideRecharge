//
//  User.swift
//  CarRemote
//
//  Created by pluto on 27.11.20.
//

import Foundation
import MapKit

let groupBundleIdentifier: String = "group.mns.RideRecharge"

extension UserDefaults {
    static let group = UserDefaults(suiteName: groupBundleIdentifier)!
}

protocol UserDelegate :AnyObject {
    func didUpdate(user: User)
    func didUpdateVehicle(user: User)
}

class User {
    
    enum credentials: String {
        case username = "volvoid"
        case password = "password"
        case vin = "vin"
    }
    
    enum attributes: String {
        case isOnboarded
    }
    
    enum home: String {
        case latitude
        case longitude
        case title
        case subtitle
    }
    
    static let shared = User()
    
    private (set) var credentials: (username: String, password: String, vin: String)?
    
    private let testCredentials = (username: "test", password: "test", vin: "test")
    
    private (set) var home: MKPointAnnotation?
    
    private (set) var vehicle: Vehicle?
    
    var isTestUser: Bool {
        guard let _ = self.credentials else {
            return false
        }
        return self.credentials!.username == testCredentials.0 && self.credentials!.password == testCredentials.1
    }
    
    weak var delegate: UserDelegate?
    
    var isOnboarded: Bool = false {
        didSet {
            UserDefaults.group.setValue(self.isOnboarded, forKey: User.attributes.isOnboarded.rawValue)
        }
    }
    
    private let isOnboardedKey: String = "isOnboarded"
    
    init() {
        
        let username = UserDefaults.group.object(forKey: User.credentials.username.rawValue) as? String ?? ""
        let password = UserDefaults.group.object(forKey: User.credentials.password.rawValue) as? String ?? ""
        let vin = UserDefaults.group.object(forKey: User.credentials.vin.rawValue) as? String ?? ""
        self.credentials = (username, password, vin)
        
        self.isOnboarded = UserDefaults.group.bool(forKey: User.attributes.isOnboarded.rawValue)
        
        self.home = self.storedHome
        
    }
    
    convenience init(username: String, password: String, vin: String) {
        self.init()
        self.credentials = (username, password, vin)
    }
    
    private var storedHome: MKPointAnnotation? {
        
        if self.isTestUser {
            return TestData.userHome
        }
        
        if
            let la = UserDefaults.group.object(forKey: User.home.latitude.rawValue) as? Double,
            let lon = UserDefaults.group.object(forKey: User.home.longitude.rawValue) as? Double,
            let t = UserDefaults.group.object(forKey: User.home.title.rawValue) as? String,
            let s = UserDefaults.group.object(forKey: User.home.subtitle.rawValue) as? String {
            let home = MKPointAnnotation()
            home.title = t
            home.subtitle = s
            home.coordinate = CLLocationCoordinate2D(latitude: la, longitude: lon)
            return home
        }
        
        return nil
    }
    
    func set(username: String, password: String, vin: String) {
        
        self.credentials = (username, password, vin)
        UserDefaults.group.setValue(username, forKey: User.credentials.username.rawValue)
        UserDefaults.group.setValue(password, forKey: User.credentials.password.rawValue)
        UserDefaults.group.setValue(vin, forKey: User.credentials.vin.rawValue)
        
        self.home = self.storedHome

        self.delegate?.didUpdate(user: self)
    }
    
    func set(home: MKPointAnnotation) {
        self.home = self.isTestUser ? TestData.userHome : home
        UserDefaults.group.setValue(home.title, forKey: User.home.title.rawValue)
        UserDefaults.group.setValue(home.subtitle, forKey: User.home.subtitle.rawValue)
        UserDefaults.group.setValue(home.coordinate.latitude, forKey: User.home.latitude.rawValue)
        UserDefaults.group.setValue(home.coordinate.longitude, forKey: User.home.longitude.rawValue)
        self.delegate?.didUpdate(user: self)
    }
    
    func set(vehicle: Vehicle) {
        self.vehicle = vehicle
        self.delegate?.didUpdateVehicle(user: self)
    }
    
}
