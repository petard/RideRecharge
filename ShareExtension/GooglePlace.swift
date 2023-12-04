//
//  GooglePlace.swift
//  CarRemote
//
//  Created by pluto on 22.10.20.
//

import Foundation
import CoreLocation


struct GooglePlaceCoordinates: Hashable, Codable {
    var lat: Double
    var lng: Double
}

struct GooglePlaceGeometry: Codable {
    fileprivate var location: GooglePlaceCoordinates
    var coordinates: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: location.lat,
            longitude: location.lng)
    }
}

struct GooglePlace: Codable {
    let name: String?
    let geometry: GooglePlaceGeometry
    let address: String?
    let phoneNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case address = "formatted_address"
        case phoneNumber = "formatted_phone_number"
        case geometry
    }
    
}

// Result for GooglePlace Search
struct GooglePlaces: Codable {
    var status: GooglePlaceResultStatus
    var results: [GooglePlace]
}

enum GooglePlaceResultStatus : String, Codable {
    case notFound = "NOT_FOUND"
    case ok = "OK"
    case invalidRequest = "INVALID_REQUEST"
}

struct GooglePlaceResult: Codable {
    let status: GooglePlaceResultStatus
    let result: GooglePlace?
}

public enum GooglePlaceServicesError: Error {
    case statusNotFound
    case statusUnknown
    case failedSearchRequest
    case failedToSerializePlaceData
    case responseUnknown
    case detailsFailedRequest
    case detailsMissingCid
    case detailsNoResults
    case detailsMissingInformation
}

extension GooglePlaceServicesError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .statusNotFound:
            return NSLocalizedString("", comment: "")
        case .statusUnknown:
            return NSLocalizedString("", comment: "")
        case .failedSearchRequest:
            return NSLocalizedString("", comment: "")
        case .failedToSerializePlaceData:
            return NSLocalizedString("", comment: "")
        case .responseUnknown:
            return NSLocalizedString("", comment: "")
        case .detailsFailedRequest:
            return NSLocalizedString("", comment: "")
        case .detailsMissingCid:
            return NSLocalizedString("Unable to read Google Maps data. Try again with different location or using Apple Maps.", comment: "")
        case .detailsNoResults:
            return NSLocalizedString("Couldn't find your location. Try again with different location or using Apple Maps.", comment: "")
        case .detailsMissingInformation:
            return NSLocalizedString("Unable to read Google Maps data. Try again with different location or using Apple Maps.", comment: "")
        }
    }
}

struct GooglePlaceServices {
        
    static var apiKey: String {
        get {
            guard let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") else {
                fatalError("Couldn't find file 'Info.plist'.")
            }
            // 2
            let plist = NSDictionary(contentsOfFile: filePath)
            guard let value = plist?.object(forKey: "Google_API_Key") as? String else {
                fatalError("Couldn't find key 'Google_API_Key' in 'Info.plist'.")
            }
            return value
        }
    }
    
    
    struct search {
        
        private static let apiEndpoint: String = "https://maps.googleapis.com/maps/api/place/textsearch/json"
        
        static func query(from url: URL) -> String? {
            // test for q parameter
            if
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                let q = queryItems.first(where: {$0.name == "q"})?.value {
                return q
            }
            
            // try match place path
            let regexPattern: String = #"(?<=place\/).+(?=\/@)"# // get the place title / description from a google query
            if let find = url.absoluteString.range(of: regexPattern, options: .regularExpression, range: nil, locale: Locale.current) {
                return String(url.absoluteString[find])
            }
            
            return nil
        }
        
        
        private static func request(query: String) -> URLRequest? {
            var components = URLComponents(string: GooglePlaceServices.search.apiEndpoint)
            components?.queryItems = [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "key", value: GooglePlaceServices.apiKey)
            ]
            guard let _ = components?.url else {
                return nil;
            }
            return URLRequest(url: components!.url!)
        }
        
        static func using(locationURL: URL) async throws -> GooglePlace {
            
            guard
                let query = GooglePlaceServices.search.query(from: locationURL),
                let request = GooglePlaceServices.search.request(query: query) else {
                throw GooglePlaceServicesError.failedSearchRequest
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
                let place = try JSONDecoder().decode(GooglePlaces.self, from: data).results.first
                if place == nil { throw GooglePlaceServicesError.failedToSerializePlaceData}
                return place!
            } catch {
                throw error
            }
            
        }
        
        
        static func using(locationURL: URL, completion: @escaping(GooglePlace?, Error?) -> Void) {
            
            guard
                let query = GooglePlaceServices.search.query(from: locationURL),
                let request = GooglePlaceServices.search.request(query: query) else {
                return;
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                guard
                    error == nil,
                    let _ = data,
                    let place = try? JSONDecoder().decode(GooglePlaces.self, from: data!).results.first
                else {
                    completion(nil, error)
                    return;
                }
                completion(place, nil)
            }.resume()
            
        }
    }
    
    struct details {
        
        private static let apiEndpoint: String = "https://maps.googleapis.com/maps/api/geocode/json" // Using geocode API is cheaper than Place API
                
        /// Create Google Maps Geocode API request using Google maps link
        /// - Parameter url: Google Maps link
        private static func request(url: URL) throws -> URLRequest { //
            
            guard
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                let address = queryItems.first(where: { $0.name == "q"})?.value,
                var components = URLComponents(string: GooglePlaceServices.details.apiEndpoint)
            else {
                throw GooglePlaceServicesError.detailsFailedRequest
            }
            
            components.queryItems = [
                URLQueryItem(name: "address", value: address),
                URLQueryItem(name: "key", value: GooglePlaceServices.apiKey)
            ]
            var request = URLRequest(url: components.url!)
            request.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
            return request
        }
        
        
        private static func request(cid: String) -> URLRequest? {
            var components = URLComponents(string: GooglePlaceServices.details.apiEndpoint)
            components?.queryItems = [
                URLQueryItem(name: "cid", value: cid),
                URLQueryItem(name: "key", value: GooglePlaceServices.apiKey)
            ]
            guard let _ = components?.url else {
                return nil;
            }
            var request = URLRequest(url: components!.url!)
            request.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
            return request
        }
        
        private static func hexToDec(string: String) -> UInt64 {
            var cid: UInt64 = 0
            Scanner(string: "\(string)").scanHexInt64(&cid)
            return cid
        }
        
        private static func cid(url: URL) throws -> String  {
            guard
                let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                let value = queryItems.first(where: { $0.name == "ftid"})?.value,
                let seperator = value.lastIndex(of: ":")
            else {
                throw GooglePlaceServicesError.detailsMissingCid
            }
            return "\(self.hexToDec(string: String(value[value.index(after: seperator)...])))"
        }
        
        
        static func using(query: String) async throws -> GooglePlace {
            
             // Use (Apple) GeoEncode provider to get address from Google URL query
             let q = query.replacingOccurrences(of: "+", with: " ")
             do {
             let placemark = try await GeoLookupService.placeFor(locationQuery: q)
             
             let geometry = GooglePlaceGeometry(location: GooglePlaceCoordinates(lat: placemark.location!.coordinate.latitude, lng: placemark.location!.coordinate.longitude))
             let nameToken = query.split(separator: ",", maxSplits: 1).map(String.init).first
             return GooglePlace(name: nameToken ?? q, geometry: geometry, address: placemark.thoroughfare, phoneNumber: nil)
             
             } catch {
             throw GooglePlaceServicesError.detailsNoResults
             }
            
        }
        
        static func using(url: URL) async throws -> GooglePlace {
            
            // Handle case when place can be resolved from URL
            if let coordinates = Coordinates(url: url) {
                let geometry = GooglePlaceGeometry(location: GooglePlaceCoordinates(lat: coordinates.latitude, lng: coordinates.longitude))
                return GooglePlace(name: "Dropped pin", geometry: geometry, address: nil, phoneNumber: nil)
            }
            
            do {
                let request = try GooglePlaceServices.details.request(url: url)
                let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
                let json = try JSONDecoder().decode(GooglePlaces.self, from: data)
                switch json.status {
                case .ok:
                    if json.results.count > 0 {
                        return(json.results.first!)
                    } else {
                        throw GooglePlaceServicesError.detailsNoResults
                    }
                case .notFound:
                    throw  GooglePlaceServicesError.statusNotFound
                default:
                    throw  GooglePlaceServicesError.statusUnknown
                }
            } catch {
                throw error
            }
        }
        
        
        static private func using(cid: String) async throws -> GooglePlace {
            
            guard let request = GooglePlaceServices.details.request(cid: cid) else {
                throw GooglePlaceServicesError.failedSearchRequest
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(for: request, delegate: nil)
                let json = try JSONDecoder().decode(GooglePlaceResult.self, from: data)
                switch json.status {
                case .ok:
                    return(json.result!)
                case .notFound:
                    throw  GooglePlaceServicesError.statusNotFound
                default:
                    throw  GooglePlaceServicesError.statusUnknown
                }
            } catch {
                throw error
            }
            
        }
        
    }
    
    
}
