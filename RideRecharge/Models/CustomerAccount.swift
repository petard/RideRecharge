//
//  CustomerAccount.swift
//  RideRecharge
//
//  Created by pluto on 01.01.21.
//

import Foundation



class CustomerAccount: Decodable {
    
    var username: String
    var firstName: String
    var lastName: String
    var accountVehicleRelations: [String]
    var vehicleRelations: [URL] {
        var re: [URL] = []
        let mapped = self.accountVehicleRelations.map { URL(string: $0)}
        for url in mapped {
            if let _ = url {
                re.append(url!)
            }
        }
        return re
    }
    
    lazy var vehicleIds: [String] = []
    
    class func load(using username: String?, password: String?) async throws -> CustomerAccount {

        guard !User.shared.isTestUser else {
            let account = try! JSONDecoder().decode(CustomerAccount.self, from: Data(TestData.customerAccount.utf8))
            let firstVehicle = try! JSONDecoder().decode(VehicleAccountRelation.self, from: Data(TestData.customerAccountVehicleRelations.utf8))
            account.vehicleIds = [firstVehicle.vehicleId]
            return account;
        }
        
        let voc = VOC(volvoid: username ?? "", password: password ?? "", vin: "")
        
        let url = URL(string: "https://vocapi.wirelesscar.net/customerapi/rest/v3.0/customeraccounts")!
        var request = URLRequest(url: url,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = voc.requestHeaders

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        if let error = ServiceError(response: response, data: data) {
            throw error
        }

        let account = try JSONDecoder().decode(CustomerAccount.self, from: data)
        
        for vehicleRelation in account.vehicleRelations {
            account.vehicleIds.append(try await VehicleAccountRelation.load(using: vehicleRelation, allHTTPHeaderFields: voc.requestHeaders).vehicleId)
        }
        
        return account
    }
    
    class func load(using allHTTPHeaderFields: [String : String]?, completion: @escaping(CustomerAccount?, ServiceError?) -> Void) {
        
        guard !User.shared.isTestUser else {
            let account = try! JSONDecoder().decode(CustomerAccount.self, from: Data(TestData.customerAccount.utf8))
            let firstVehicle = try! JSONDecoder().decode(VehicleAccountRelation.self, from: Data(TestData.customerAccountVehicleRelations.utf8))
            account.vehicleIds = [firstVehicle.vehicleId]
            completion(account, nil)
            return;
        }

        
        let url = URL(string: "https://vocapi.wirelesscar.net/customerapi/rest/v3.0/customeraccounts")!
        var request = URLRequest(url: url,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = allHTTPHeaderFields
        
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            guard let _ = data, let account = try? JSONDecoder().decode(CustomerAccount.self, from: data!) else {
                completion(nil, ServiceError(response: response))
                return
            }
            
            guard !account.vehicleRelations.isEmpty else {
                completion(account, nil);
                return;
            }
            
            // fetch VINs for all vehicles
            let group = DispatchGroup()
            
            for vehicleRelation in account.vehicleRelations {
                group.enter()
                VehicleAccountRelation.load(using: vehicleRelation, allHTTPHeaderFields: allHTTPHeaderFields) { (relation, error) in
                    if let _ = relation {
                        account.vehicleIds.append(relation!.vehicleId)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: DispatchQueue.global()) {
              print("Completed work loading vehicles")
                completion(account, nil);
                return;
            }

        })

        dataTask.resume()
    }

}

class VehicleAccountRelation: Decodable {
    var vehicleId: String //
    var username: String
    var status: String
    var vehicle: String
    
    static func load(using url: URL, allHTTPHeaderFields: [String : String]?) async throws -> VehicleAccountRelation {
        
        var request = URLRequest(url: url,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = allHTTPHeaderFields

        let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
        if let error = ServiceError(response: response, data: data) {
            throw error
        }
        return try JSONDecoder().decode(VehicleAccountRelation.self, from: data)
    }
    
    
    static func load(using url: URL, allHTTPHeaderFields: [String : String]?, completion: @escaping(VehicleAccountRelation?, ServiceError?) -> Void) {
        
        var request = URLRequest(url: url,
                                                cachePolicy: .useProtocolCachePolicy,
                                            timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = allHTTPHeaderFields
        
        let dataTask = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            guard let _ = data, let relation = try? JSONDecoder().decode(VehicleAccountRelation.self, from: data!) else {
                completion(nil, ServiceError(response: response))
                return
            }
            
            completion(relation, nil)
        })

        dataTask.resume()

    }
}
