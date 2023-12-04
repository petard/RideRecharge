//
//  ChargeLocation.swift
//  ShareExtension
//
//  Created by pluto on 28.10.20.
//

import Foundation
import MapKit

class ChargeLocation: NSObject, MKAnnotation {
    
    // MKAnnotation
    
    var coordinate: CLLocationCoordinate2D
    
    var title: String? {
        get {
        return self.locationOperator ?? "Unknown Operator"
        }
    }
    
    var subtitle: String? {
        get {
            return self.postalAddress ?? "\(self.coordinate.latitude),\(self.coordinate.longitude)"
        }
    }
    
    // Class
    
    var location: CLLocation {
        get {
            return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }
    
    var availableChargePoints: Int = 0
    var numberOfChargePoints: Int = 0
    
    var maxPowerInKw: Double = 0
    
    var postalAddress: String?
    var locationOperator: String?
    
    var availability: Status {
        get {
            return availableChargePoints > 0 ? .available : .occupied
        }
    }
    
    enum Status: String, Codable {
        case available = "Available"
        case occupied = "Occupied"
        case unkown = "Unknown"
        case offline = "Offline"
    }

    init(availableChargePoints: Int, numberOfChargePoints: Int, maxPowerInKw: Double, postalAddress: String?, locationOperator: String?, coordinate: CLLocationCoordinate2D) {
        self.availableChargePoints = availableChargePoints
        self.numberOfChargePoints = numberOfChargePoints
        self.maxPowerInKw = maxPowerInKw
        self.postalAddress = postalAddress
        self.locationOperator = locationOperator
        self.coordinate = coordinate
    }
    
    
    class ENBW: ChargeLocation, Decodable {
        
        var grouped: Bool
        
        enum CodingKeys: String, CodingKey {
            case latitude = "lat"
            case longitude = "lon"
            case locationOperator = "operator"
            case postalAddress = "shortAddress"
            case availableChargePoints, numberOfChargePoints, maxPowerInKw, grouped
        }
        
        required init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            
            grouped = try values.decode(Bool.self, forKey: .grouped)

            super.init(
                availableChargePoints: try values.decode(Int.self, forKey: .availableChargePoints),
                numberOfChargePoints: try values.decode(Int.self, forKey: .numberOfChargePoints),
                maxPowerInKw: try values.decode(Double.self, forKey: .maxPowerInKw),
                postalAddress: try? values.decode(String.self, forKey: .postalAddress),
                locationOperator: try values.decode(String.self, forKey: .locationOperator),
                coordinate: CLLocationCoordinate2D(
                    latitude: try values.decode(Double.self, forKey: .latitude),
                    longitude: try values.decode(Double.self, forKey: .longitude)
                )
            )
        }
        
    }
    
    class TomTom: ChargeLocation, Decodable {
        
        enum CodingKeys: CodingKey {
            case id, address, poi, position
            
            enum AddressCodingKeys: String, CodingKey {
                case freeformAddress
            }
            
            enum POICodingKeys: String, CodingKey {
                case name
            }
            
            enum PositionCodingKeys: String, CodingKey {
                case lat
                case lon
            }

        }
        
        var id: String
        
        required init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let addressContainer = try values.nestedContainer(keyedBy: CodingKeys.AddressCodingKeys.self, forKey: .address)
            let positionContainer = try values.nestedContainer(keyedBy: CodingKeys.PositionCodingKeys.self, forKey: .position)
            let poiContainer = try values.nestedContainer(keyedBy: CodingKeys.POICodingKeys.self, forKey: .poi)

            
            id = try values.decode(String.self, forKey: .id)
                                                
            super.init(
                availableChargePoints: 0,
                numberOfChargePoints: 0,
                maxPowerInKw: 0,
                postalAddress: try addressContainer.decode(String.self, forKey: .freeformAddress),
                locationOperator: try poiContainer.decode(String.self, forKey: .name),
                coordinate: CLLocationCoordinate2D(
                    latitude: try positionContainer.decode(Double.self, forKey: .lat),
                    longitude: try positionContainer.decode(Double.self, forKey: .lon)
                )
            )
        }
        
    }

    
}
