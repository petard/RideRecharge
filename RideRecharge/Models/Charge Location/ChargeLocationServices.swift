//
//  ChargeLocationServices.swift
//  RideRecharge
//
//  Created by yuri on 27.07.22.
//

import Foundation
import MapKit

struct ChargeLocationServices {
    
    var postalAddress: String
    
    // Helper functions to normalize inputs
    
    private static let geocoder = CLGeocoder()
    
    
    private static func lookUp(location: CLLocation, completionHandler: @escaping (CLPlacemark?)
                               -> Void ) {
        // Use the last reported location.
        
        
        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(location,
                                        completionHandler: { (placemarks, error) in
            
            if error != nil {
                
            } else {
                completionHandler(placemarks?.first)
            }
            
        })
    }
    
    private static func normalize(_ input: String?) -> String? {
        if input == "*" { // Allego stations names have * has name for unknown reason in API response
            return nil
        }
        
        return input?.components(separatedBy: " - ").first?.components(separatedBy: " GmbH").first ?? input
    }
    
    
    /// Service for Tom Tom APIs
    struct TomTom {
        
        static var apiKey: String {
            get {
                guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
                    fatalError("Couldn't find file 'Info.plist'.")
                }
                // 2
                let plist = NSDictionary(contentsOfFile: filePath)
                guard let value = plist?.object(forKey: "TomTom_API_Key") as? String else {
                    fatalError("Couldn't find key 'TomTom_API_Key' in 'Info.plist'.")
                }
                return value
            }
        }
     
        private static let apiAvailbilityHostUrl = "https://api.tomtom.com/search/2/chargingAvailability.json"
        private static let apiSearchHostUrl = "https://api.tomtom.com/search/2/categorySearch/.json"
        
        /// helper struct to decode search results json
        private struct SearchResult: Decodable {
            var results: [ChargeLocation.TomTom]
        }
        
        private class ChargingAvailability: Decodable {
            var connectors: [Connector]
            
            var availableChargePoints: Int {
                return connectors.reduce(0) { $0 + $1.availability.current.available }
            }
            
            var totalNumberOfChargePoints: Int {
                return connectors.reduce(0) { $0 + $1.availability.current.total }
            }
            
            var unknownStatusChargePoints: Int {
                return connectors.reduce(0) { $0 + $1.availability.current.unknown }
            }
            
            var maxPowerInKw: Double {
               return connectors.map { $0.availability.perPowerLevel.max(by: {$0.powerKW < $1.powerKW })!.powerKW }.max() ?? 0
            }
                        
            class Connector: Decodable {
                var plugType: String!
                var availability: Availability!
                
                class Availability: Decodable {
                    var current: AvailabilityCurrent
                    var perPowerLevel: [AvailabilityPerPowerLevel]
                }
                
                class AvailabilityCurrent: Decodable {
                    
                    var total:Int {
                        get {
                            return available + occupied + reserved + outOfService + unknown
                        }
                    }
                    
                    var available: Int
                    var occupied: Int
                    var reserved: Int
                    var outOfService: Int
                    var unknown: Int
                }
                
                class AvailabilityPerPowerLevel: Decodable {
                    var powerKW: Double
                }
                                
                enum CodingKeys: String, CodingKey {
                    case plugType = "type", availability
                }

            }
        }
        
        private static func stationAvailability(id: String) async throws -> TomTom.ChargingAvailability {
            // configure request
            let headers = [
                "Accept": "application/json",
                "Accept-Encoding": "gzip, deflate, br",
            ]
            
            var comp = URLComponents(string: apiAvailbilityHostUrl)!
            
            comp.queryItems = [
                URLQueryItem(name: "chargingAvailability", value: "\(id)"),
                URLQueryItem(name: "key", value: "\(apiKey)")
            ]
            // perform request and parse response

            var request = URLRequest(url: comp.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "GET"
            
            request.allHTTPHeaderFields = headers
            
            let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
            return try JSONDecoder().decode(TomTom.ChargingAvailability.self, from: data)
        }
        
        
        static func nearBy(location: CLLocationCoordinate2D, distanceInMeter: Double = 2000) async throws -> [ChargeLocation.TomTom] {
            // configure request
            let headers = [
                "Accept": "application/json",
                "Accept-Encoding": "gzip, deflate, br",
            ]
            
            var comp = URLComponents(string: apiSearchHostUrl)!
            comp.queryItems = [
                URLQueryItem(name: "lat", value: "\(location.latitude)"),
                URLQueryItem(name: "lon", value: "\(location.longitude)"),
                URLQueryItem(name: "categorySet", value: "7309"), // EV Charging Station category
              //  URLQueryItem(name: "view", value: "unified"),
                URLQueryItem(name: "limit", value: "20"), // default = 10
                URLQueryItem(name: "radius", value: "\(distanceInMeter)"),
                URLQueryItem(name: "key", value: "\(apiKey)")
            ]
            
            var request = URLRequest(url: comp.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "GET"
            
            request.allHTTPHeaderFields = headers
            
            let (data,_) = try await URLSession.shared.data(for: request, delegate: nil)
            let searchresult = try JSONDecoder().decode(ChargeLocationServices.TomTom.SearchResult.self, from: data)
            //print("lat \(location.latitude) lon\(location.longitude)")
            let filteredLocations = try await searchresult.results.concurrentMap() { chargestation in

                // some data normalization
                if chargestation.postalAddress == nil {
                    chargestation.postalAddress = try? await GeoLookupService.location(coordinates: chargestation.coordinate)
                }
                
                if chargestation.postalAddress == nil {
                    ChargeLocationServices.lookUp(location: chargestation.location, completionHandler: { placemark in
                        chargestation.postalAddress = placemark?.postalAddress?.street
                    })
                } else {
                    chargestation.postalAddress = chargestation.postalAddress?.components(separatedBy: ", ").first
                }
                
                // get availability status
                do {
                    let availability = try await TomTom.stationAvailability(id: chargestation.id)
                    // omit locations without charging state information
                    if availability.totalNumberOfChargePoints == availability.unknownStatusChargePoints {
                        chargestation.numberOfChargePoints = 0
                        chargestation.availableChargePoints = 0
                        chargestation.maxPowerInKw = 0
                    } else {
                        chargestation.availableChargePoints = availability.availableChargePoints
                        chargestation.numberOfChargePoints = availability.totalNumberOfChargePoints
                        chargestation.maxPowerInKw = Double(availability.maxPowerInKw)
                    }
                } catch {
                    print(error)
                }
                                
                return chargestation
            }
            return filteredLocations.filter({ $0.numberOfChargePoints > 0 })
        }
        
    }
    
    struct ENBW {
        
        static var apiKey: String {
            get {
                guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
                    fatalError("Couldn't find file 'Info.plist'.")
                }
                // 2
                let plist = NSDictionary(contentsOfFile: filePath)
                guard let value = plist?.object(forKey: "ENBW_API_Key") as? String else {
                    fatalError("Couldn't find key 'ENBW_API_Key' in 'Info.plist'.")
                }
                return value
            }
        }
        
        private static let apiHostUrl = "https://enbw-emp.azure-api.net/emobility-public-api/api/v1/chargestations"
        
        private static func apiRequest(bottomLeft: MKMapPoint, topRight: MKMapPoint) async throws -> [ChargeLocation.ENBW] {
            
            // configure request
            let headers = [
                "Accept": "application/json",
                "Origin": "https://www.enbw.com",
                "Referer": "https://www.enbw.com/",
                "Host": "enbw-emp.azure-api.net",
                "Accept-Language": "de",
                "Accept-Encoding": "gzip, deflate, br",
                "Ocp-Apim-Subscription-Key": ChargeLocationServices.ENBW.apiKey
            ]
            
            var comp = URLComponents(string: ChargeLocationServices.ENBW.apiHostUrl)!
            
            comp.queryItems = [
                URLQueryItem(name: "fromLat", value: "\(bottomLeft.coordinate.latitude)"),
                URLQueryItem(name: "toLat", value: "\(topRight.coordinate.latitude)"),
                URLQueryItem(name: "fromLon", value: "\(bottomLeft.coordinate.longitude)"),
                URLQueryItem(name: "toLon", value: "\(topRight.coordinate.longitude)"),
                URLQueryItem(name: "grouping", value: "false"),
                URLQueryItem(name: "groupingDivisor", value: "15")
                
            ]
            
            var request = URLRequest(url: comp.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "GET"
            
            request.allHTTPHeaderFields = headers
            
            let (data,_) = try await URLSession.shared.data(for: request, delegate: nil)
            return try await JSONDecoder().decode([ChargeLocation.ENBW].self, from: data).concurrentMap() { location in
                //print("title: \(location.title), address: \(location.postalAddress), operator: \(location.locationOperator)")
                // some data normalization
                location.locationOperator = ChargeLocationServices.normalize(location.locationOperator)
                if location.postalAddress == nil {
                    location.postalAddress = try? await GeoLookupService.location(coordinates: location.coordinate)
                }
                
                if location.postalAddress == nil {
                    ChargeLocationServices.lookUp(location: location.location, completionHandler: { placemark in
                        location.postalAddress = placemark?.postalAddress?.street
                    })
                } else {
                    location.postalAddress = location.postalAddress?.components(separatedBy: ", ").first
                }
                return location
            }
        }
        
        
        static func nearBy(location: CLLocationCoordinate2D, distanceInMeter: Double = 1000) async throws -> [ChargeLocation.ENBW] {
            // calc radius
            let circle = MKCircle(center: location, radius: distanceInMeter)
            
            let bottomLeft = MKMapPoint(x: circle.boundingMapRect.minX, y: circle.boundingMapRect.maxY)
            let topRight = MKMapPoint(x: circle.boundingMapRect.maxX, y: circle.boundingMapRect.minY)
            // configure request
            return try await apiRequest(bottomLeft: bottomLeft, topRight: topRight)
            
        }
        
        static func within(mapRect: MKMapRect) async throws -> [ChargeLocation.ENBW] {
            
            let circle = MKCircle(mapRect: mapRect)
            
            let bottomLeft = MKMapPoint(x: circle.boundingMapRect.minX, y: circle.boundingMapRect.maxY)
            let topRight = MKMapPoint(x: circle.boundingMapRect.maxX, y: circle.boundingMapRect.minY)
            
            return try await apiRequest(bottomLeft: bottomLeft, topRight: topRight)
        }
    }
}

extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

extension Sequence {
    func concurrentMap<T>(
        _ transform: @escaping (Element) async throws -> T
    ) async throws -> [T] {
        let tasks = map { element in
            Task {
    try await transform(element)
}
        }

        return try await tasks.asyncMap { task in
            try await task.value
        }
    }
}
