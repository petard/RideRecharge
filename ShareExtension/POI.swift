//
//  POI.swift
//  CarRemote
//
//  Created by pluto on 22.10.20.
//

import Foundation
import CoreLocation
import MapKit

class POI: NSObject, Codable, MKAnnotation {
    var title: String?
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: position.latitude,
            longitude: position.longitude)
    }
    
    var position: Coordinates
    
    var subtitle: String?
    
    private enum CodingKeys: String, CodingKey {
        case title = "name"
        case subtitle = "description"
        case position
    }
    
    init(place: GooglePlace) {
        title = place.name
        position = Coordinates(latitude: place.geometry.coordinates.latitude, longitude: place.geometry.coordinates.longitude)
        if let _ = place.address {
            subtitle = place.address!
        }
        if let _ = place.phoneNumber {
            if let _ = subtitle {
                subtitle! += ", \(place.phoneNumber!)"
            } else {
                subtitle! = "\(place.phoneNumber!)"
            }
        }
    }
    
    init(place: CLPlacemark) {
        title = place.name
        position = Coordinates(coordinate:  place.location!.coordinate)
        subtitle = place.thoroughfare
    }
    
    init(annotation: MKAnnotation) {
        title = annotation.title ?? ""
        subtitle = annotation.subtitle ?? ""
        position = Coordinates(coordinate: annotation.coordinate)
    }
    
    
    init(title: String, position: Coordinates, subtitle: String) {
        self.title = title
        self.position = position
        self.subtitle = subtitle
    }
    
}

struct Coordinates: Hashable, Codable {
    var latitude: Double
    var longitude: Double
    
    var string: String {
        return "Coordinates: \(self.latitude), \(self.longitude)"
    }
    
    var coordinates: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init?(string: String) {
        let components = string.split(separator: ",")
        guard let lat = Double(components[0]) else {
            return nil;
        }
        guard let lng = Double(components[1]) else {
            return nil;
        }
        self.latitude = lat
        self.longitude = lng
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    private static func splitter(query: String) -> (Double, Double)? {
        let c = query.split(separator: ",")
        guard
            c.count == 2,
            let lat = Double(c[0]),
            let lng = Double(c[1])
        else {
            return nil
        }
        return (lat, lng)
    }
    
    init?(url: URL) {
        // first try q parameter
        if
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
            let q = queryItems.first(where: {$0.name == "q"})?.value,
            let values = Coordinates.splitter(query: q) {
            self.latitude = values.0
            self.longitude = values.1
            return;
        }
        
        // try matching place path
        let regexPattern: String = #"(?<=\/@)-?\d+.\d+,-?\d+.\d+(?=,)"# // match Google Maps URL contains coordinates
        guard
            let find = url.absoluteString.range(of: regexPattern, options: .regularExpression, range: nil, locale: Locale.current)
        else {
            return nil
        }
        
        let c = url.absoluteString[find].split(separator: ",")
        guard
            c.count == 2,
            let lat = Double(c[0]),
            let lng = Double(c[1])
        else {
            return nil
        }
        self.latitude = lat
        self.longitude = lng
    }
    
}
