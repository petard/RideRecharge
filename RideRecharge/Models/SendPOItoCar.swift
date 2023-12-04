//
//  CarServices.swift
//  CarRemote
//
//  Created by pluto on 31.10.20.
//

import Foundation
import MapKit

struct SendPOItoCar: Encodable {
    
    var pois: [POI] = []
    
    private func trim(s: String) -> String {
        let charLimit: Int = 20 // VOC APi and Sensus Navigation limit title to 20 utf-8 characters
        let more: String = "…"
        if s.utf8.count > charLimit {
            let index = s.utf8.index(s.utf8.startIndex, offsetBy: (charLimit - more.utf8.count))
            return s[..<index].trimmingCharacters(in: .whitespaces) + more
        } else {
            return s
        }
    }
    
    private func formatPOI(_ poi: POI) -> POI {
        // remove line breaks
        poi.title = poi.title?.replacingOccurrences(of: "\n", with: ", ")
        poi.subtitle = poi.subtitle?.replacingOccurrences(of: "\n", with: ", ")
        // trim
        if let _ = poi.title {
            poi.title = self.trim(s: poi.title!)
        }
        return poi
    }
    
    init(pois: [POI]) {
        self.pois = pois.map{self.formatPOI($0)}
    }
    
    init(annotations: [MKAnnotation]) {
        self.pois = annotations.map {self.formatPOI(POI(annotation: $0))}
    }
    
    func encoded() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
}

extension SendPOItoCar {
    
     struct Service {
         
         static func isSending() -> Bool {
             if URLSession.shared.delegateQueue.operations.count > 0 {
                 return true
             }
             
             return false
         }
         
         static func send(_ annotations: [MKAnnotation]) async throws {
             
             let payload = try SendPOItoCar(annotations: annotations).encoded()
             let url = URL(string: VOC.shared.baseUrl + "/pois")!
             
             var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
             request.httpMethod = "POST"
             request.allHTTPHeaderFields = VOC.shared.requestHeaders
             request.httpBody = payload
             
             let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
             if let error = ServiceError(response: response, data: data) {
                 throw error
             }
             
             for _ in 0...2 {
                 try await Task.sleep(nanoseconds: UInt64(2.0 * Double(NSEC_PER_SEC)))
                 let result = try await VOC.shared.service(data: data)
                 if result == .successful {
                     return;
                 }
             }
             
         }
        
        // The API requires an array of annotations; on current vehicles, only one location can be processed by the car navigation (FIFO)
        static func sendSync(_ annotations: [MKAnnotation], completion: @escaping(ServiceError?) -> Void) {
            
            let data = SendPOItoCar(annotations: annotations)
                    
            guard let payload = try? JSONEncoder().encode(data) else {
                completion(ServiceError.unknown)
                return;
            }
            let url = URL(string: VOC.shared.baseUrl + "/pois")!
            
            var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields = VOC.shared.requestHeaders
            request.httpBody = payload
            
            let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
               // print("debug pois request", error, String(data: payload, encoding: .utf8)!)

                guard
                    error == nil,
                    let _ = data,
                    let service = try? JSONDecoder().decode(VOC.Service.self, from: data!),
                    let serviceUrl = URL(string: service.service)
                else {
                    completion(ServiceError(response: response, data: data))
                    return;
                }
                
                // Call service api to retrieve status
                let delayBySeconds = 3.0
                DispatchQueue.main.asyncAfter(deadline: .now() + delayBySeconds) {
                    VOC.shared.service(url: serviceUrl) { (service, error) in
                        // debug output
                        //print("debug pois service", error, service)

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
                            //print("debug pois service2", error, service)
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
    
}


