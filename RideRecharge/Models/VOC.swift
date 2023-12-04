//
//  Config.swift
//  CarRemote
//
//  Created by pluto on 31.10.20.
//

import Foundation


class VOC {
    
    struct ServiceResponse: Codable {
        let httpStatusCode: Int
    }
    
    struct Service: Codable {
        
        let status: String
        let failureReason: String?
        let service: String // serviceUrl
        let vehicleId: String
        let customerServiceId: String

        // Error responses
        let errorDescription: String?
        let errorLabel: String?
        let statusCode: String?
        let message: String?
        
        enum Status: String {
            case successful = "Successful" // Received by car; final state
            case started = "Started" // Received by server / Acknowledged?; intermediate state
            case messageDelivered = "MessageDelivered" // Received by server / delivered to car?; intermediate state
            case queued = "Queued"
            case unknown
            
            init(service: Service) {
                switch service.status {
                case Service.Status.successful.rawValue:
                    self = .successful
                case Service.Status.started.rawValue:
                    self = .started
                case Service.Status.messageDelivered.rawValue:
                    self = .messageDelivered
                case Service.Status.queued.rawValue:
                    self = .queued
                default:
                    self = .unknown
                }
            }
        }
    }
    
    struct Error: Decodable {
        let errorLabel: String
        let errorDescription: String
    }
    
    static let shared = VOC()
    
    var baseUrl: String {
        return "https://vocapi.wirelesscar.net/customerapi/rest/v3.0/vehicles/\(self.vin)"
    }
    
    static let dateFormat: String = "yyyy-MM-dd'T'HH:mm:ss+SSSS"
    
    var requestHeaders: [String: String] {
        
        let userPasswordData = "\(volvoid):\(password)".data(using: .utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
        
        return [
            "x-device-id": "Device",
            "x-os-type": "Android",
            "x-originator-type": "App",
            "x-os-version": "22",
            "cache-control": "no-cache",
            "content-type": "application/json",
            "authorization": "Basic \(base64EncodedCredential)"
        ]
    }
    
    private (set) var volvoid: String
    private var password: String
    private var vin: String
    
    convenience init() {
        self.init(volvoid: User.shared.credentials?.username ?? "", password: User.shared.credentials?.password ?? "", vin: User.shared.credentials?.vin ?? "")
        User.shared.delegate = self
    }
    
    init(volvoid: String, password: String, vin: String) {
        self.volvoid = volvoid
        self.password = password
        self.vin = vin
        User.shared.delegate = self
    }
    
    func set(volvoid: String, password: String, vin: String) {
        self.volvoid = volvoid
        self.password = password
        self.vin = vin
    }
    
    func data(for url: URL) async throws -> (Data) {
        var serviceRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        serviceRequest.httpMethod = "GET"
        serviceRequest.url = url
        serviceRequest.allHTTPHeaderFields = self.requestHeaders

        let (data, response) = try await URLSession.shared.data(for: serviceRequest, delegate: nil)
        if let error = ServiceError(response: response, data: data) {
            throw error
        }
        return data
    }
    
    func service(data: Data) async throws -> Service.Status {
        let sendResult = try JSONDecoder().decode(VOC.Service.self, from: data)
        guard let serviceUrl = URL(string: sendResult.service) else {
            throw ServiceError.unknown
        }
        return try await VOC.shared.service(url: serviceUrl)
    }
    
    func service(url: URL) async throws -> Service.Status {
        let data = try await self.data(for: url)
        //print("service", String(data: data, encoding: .utf8))
        let result =  try JSONDecoder().decode(VOC.Service.self, from: data)
        return Service.Status(service: result)
    }
    
    func service(url: URL, completion: @escaping(Service?, ServiceError?) -> Void) {
        var serviceRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        serviceRequest.httpMethod = "GET"
        serviceRequest.url = url
        serviceRequest.allHTTPHeaderFields = self.requestHeaders
        let serviceTask = URLSession.shared.dataTask(with: serviceRequest, completionHandler: { (data, response, error) -> Void in
            guard
                error == nil,
                let _ = data,
                let service = try? JSONDecoder().decode(VOC.Service.self, from: data!),
                service.failureReason == nil
            else {
                completion(nil, ServiceError(response: response))
                return;
            }
            completion(service, nil)
        })
        serviceTask.resume()
    }
    
   
    
    func post(body: Data?, url: URL, completion: @escaping(ServiceError?) -> Void) {
                
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = VOC.shared.requestHeaders
        request.httpBody = body
        
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            //print("debug voc post request", error, String(data: data ?? Data(), encoding: .utf8)!)

            guard
                error == nil,
                let _ = data,
                let service = try? JSONDecoder().decode(VOC.Service.self, from: data!),
                let serviceUrl = URL(string: service.service)
            else {
                completion(ServiceError(response: response))
                return;
            }
            
            // Call service api to retrieve status
            let delayBySeconds = 3.0
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBySeconds) {
                VOC.shared.service(url: serviceUrl) { (service, error) in
                    // debug output
                  //  print("debug voc post request", error, service)

                    guard
                        error == nil
                    else {
                        completion(error)
                        return;
                    }
                    if service?.status == VOC.Service.Status.successful.rawValue {
                        completion(nil)
                        return;
                    }
                    VOC.shared.service(url: serviceUrl) { (service2, error) in
                       // print("debug pois service2", error, service)
                        guard
                            error == nil,
                            service?.failureReason != nil
                        else {
                            completion(error)
                            return;
                        }
                        completion(nil)
                    }
                }
                return;
            }
        })

        dataTask.resume()
        
    }

}


extension VOC: UserDelegate {
    func didUpdateVehicle(user: User) {
        //
    }
    
    func didUpdate(user: User) {
        self.volvoid = User.shared.credentials?.username ?? ""
        self.password = User.shared.credentials?.password ?? ""
        self.vin = User.shared.credentials?.vin ?? ""
    }
}

enum ServiceError: Error, LocalizedError {
    case networkUnavailable
    case authenticationFailed
    case serviceFailed
    case unknown
    case vehicleNotReachable
    case VINUnknown
    case noVehiclesFound
    case VINMultipleVehicles(vehicleIds: [String])

    public var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return NSLocalizedString("Volvo On Car authentication failed, Volvo ID or password wrong.", comment: "VOC Authentication")
        case .networkUnavailable:
            return NSLocalizedString("No Internet connection", comment: "Network")
        case .serviceFailed:
            return NSLocalizedString("Volvo On Car service failed", comment: "VOC Service")
        case .vehicleNotReachable:
            return NSLocalizedString("Car is in stand by. ", comment: "VOC Service")
        case .VINUnknown:
            return NSLocalizedString("No vehicles found for this account.", comment: "Customer Account")
        case .noVehiclesFound:
            return NSLocalizedString("No vehicles found for this account. This app supports vehicles with Sensus Entertainment (model year 2015-2022). Vehicles from 2022 or newer and / or have AAOS are not supported.", comment: "Customer Account")
        case .VINMultipleVehicles:
            return NSLocalizedString("Multiple vehicles registered", comment: "Customer Account")
        case .unknown:
            return NSLocalizedString("Unknown error occured", comment: "Unkown")
        }
    }
    
    public init?(response: URLResponse?, data: Data? = nil) {
        guard let r = response as? HTTPURLResponse else {
            self = .unknown
            return;
        }
        
        switch r.statusCode {
        case 200...299:
            return nil
        case 500:
            if
                let _ = data,
                let error = try? JSONDecoder().decode(VOC.Error.self, from: data!),
                error.errorLabel == "ServiceUnableToStart" {
                self = .vehicleNotReachable
            } else {
                self = .serviceFailed
            }
            break;
        case 401, 423:
            self = .authenticationFailed
            break;
        default:
            self = .unknown
            break;
        }
    }

}
