//
//  Weather.swift
//  CarRemote
//
//  Created by pluto on 05.11.20.
//

import Foundation
import CoreLocation


class Weather {
    
    var temperature: Double?
    
    class HERE: Weather, Decodable {
        
        class Observations: Decodable {
            var location: [Observation]
        }
        
        class Observation: Decodable {
            var observation: [Reading]
        }
        
        class Reading: Decodable {
            var temperature: String
        }
        
        var observations: Observations
        
    }

    class OpenMeteo: Weather, Decodable {
                
        enum CodingKeys: String, CodingKey {
            case currentWeather
            
            enum CurrentWeatherCodingKeys: String, CodingKey {
                case temperature
            }
        }
        
        required init(from decoder: Decoder) throws {
            super.init()
            let rootContainer = try decoder.container(keyedBy: CodingKeys.self)
            let weatherContainer = try rootContainer.nestedContainer(keyedBy: CodingKeys.CurrentWeatherCodingKeys.self, forKey: .currentWeather)
            temperature = try weatherContainer.decode(Double.self, forKey: .temperature)
        }
    }
    
}

struct WeatherService {
    
    struct OpenMeteo {
                
        static func current(location: CLLocationCoordinate2D) async throws -> Weather.OpenMeteo {
            // configure request
            let headers = [
                "Accept": "application/json",
                "Accept-Encoding": "gzip, deflate, br",
            ]
            let apiSearchHostUrl = "https://api.open-meteo.com/v1/forecast"
            
            var comp = URLComponents(string: apiSearchHostUrl)!
            comp.queryItems = [
                URLQueryItem(name: "latitude", value: "\(location.latitude)"),
                URLQueryItem(name: "longitude", value: "\(location.longitude)"),
                URLQueryItem(name: "current_weather", value: "true")
            ]
            
            var request = URLRequest(url: comp.url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
            request.httpMethod = "GET"
            
            request.allHTTPHeaderFields = headers
            
            let (data,_) = try await URLSession.shared.data(for: request, delegate: nil)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Weather.OpenMeteo.self, from: data)
        }
        
    }
}
