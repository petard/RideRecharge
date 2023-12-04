//
//  Vehicle+Operations.swift
//  CarRemote
//
//  Created by pluto on 10.12.20.
//

import Foundation


extension Vehicle {
    
    func carLocked(newState: Bool, completion: @escaping(Error?) -> Void) {
        
        let carLockedEndpoint: String = newState ? "/lock" : "/unlock"
        
        let url: URL = URL(string: VOC.shared.baseUrl + carLockedEndpoint)!
        
        VOC.shared.post(body: nil, url: url) { [weak self] (error) in
            guard error == nil else {
                completion(error)
                return;
            }
            self?.status?.carLocked = newState
            completion(nil)
        }
        
    }
    
    func setHeater(enabled: Bool, completion: @escaping(Error?) -> Void) {
        
        let action: String = enabled ? "/start" : "/stop"
        
        let endpoint: String
        if let _ = attributes {
            if self.attributes!.remoteHeaterSupported {
                endpoint = "/heater"
            } else if self.attributes!.preclimatizationSupported {
                endpoint = "/preclimatization"
            } else {
                return
            }
        } else {
            return
        }
                        
        let url = URL(string: VOC.shared.baseUrl + endpoint + action)!
        
        VOC.shared.post(body: nil, url: url) { [weak self] (error) in
            guard error == nil else {
                completion(error)
                return;
            }
            self?.status?.heater.status = enabled ? .on : .off
            completion(nil)
        }        

    }    
    
}
