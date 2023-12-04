//
//  LookUpService.swift
//  RideRecharge
//
//  Created by yuri on 28.07.22.
//

import Foundation
import MapKit
import Contacts

struct GeoLookupService {
    
    struct Nominatim: Decodable {
        
        var display_name: String
        var address: Address
        
        struct Address: Decodable {
            var house_number: String?
            var road: String
        }
        
        static func reverseGeocodeLocation(location: CLLocation) async throws -> String? {
            
            // configure request
            var comp = URLComponents(string: "https://nominatim.openstreetmap.org/reverse.php")!
            
            comp.queryItems = [
                URLQueryItem(name: "lat", value: "\(location.coordinate.latitude)"),
                URLQueryItem(name: "lon", value: "\(location.coordinate.longitude)"),
                URLQueryItem(name: "format", value: "jsonv2"),
            ]
            
            var request = URLRequest(url: comp.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "GET"
            
            let (data,_) = try await URLSession.shared.data(for: request, delegate: nil)
            
            let placemark = try JSONDecoder().decode(Nominatim.self, from: data)
            if let _ = placemark.address.house_number {
                return "\(placemark.address.road) \(placemark.address.house_number!)"
            } else {
                return placemark.address.road
            }

        }
    }
    
    struct Apple {
        
        static func placeFor(coordinates: CLLocation) async throws -> String? {
            
            let placemark = try await CLGeocoder().reverseGeocodeLocation(coordinates).first
        
            guard let _ = placemark?.thoroughfare else {
                return nil;
            }
            
            if let _ = placemark?.subThoroughfare {
                return "\(placemark!.thoroughfare!) \(placemark!.subThoroughfare!)"
            } else {
                return placemark!.thoroughfare!
            }
            
        }
        
        static func placeFor(locationQuery: String) async throws -> CLPlacemark {
            
            do {
                let placemark = try await CLGeocoder().geocodeAddressString(locationQuery)
                print("debug 13.154106 placemarks", placemark)
                return placemark.first!
            } catch let err as CLError {
                
                throw err
                
            }
        }
        
    }
    
    static func placeFor(locationQuery: String) async throws -> CLPlacemark {
        let placemark = try await Apple.placeFor(locationQuery: locationQuery)
        return placemark
    }
    
    static func location(coordinates: CLLocationCoordinate2D) async throws -> String? {
        
        do {
            return try await Apple.placeFor(coordinates: CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude))
        } catch {
            print(error)
            return nil
        }

    }
    
}
