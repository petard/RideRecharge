//
//  VOCService.swift
//  Juice
//
//  Created by yuri on 07.01.22.
//

import Foundation

class VOCSession {
    
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data) {
        var serviceRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        serviceRequest.httpMethod = "GET"
        serviceRequest.url = url
        serviceRequest.allHTTPHeaderFields = self.requestHeaders

        let (data, response) = try await URLSession.shared.data(for: serviceRequest, delegate: nil)
        if let error = ServiceError(response: response, data: data) {
            throw error
        }
    }
    
    
}
