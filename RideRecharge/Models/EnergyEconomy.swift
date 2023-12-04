//
//  EnergyEconomy.swift
//  CarRemote
//
//  Created by pluto on 26.12.20.
//

import Foundation

class EnergyEconomy {
    
    static let defaultElectricalConsumption: Int = 100 // This default of 100 Watts is used when the API JSON response has a null value
    static let defaultFuellConsumption: Int = 100 // This default of 100ml liter is used when the API JSON response has a null value

    /// Calcluates the engery consumption in kWh / 100km for trips in Pure Mode
    /// - Parameter trips: Array of trips including Hybrid and Pure Mode trips
    
    static func per100km(distance: Int, energy: Int) -> Double {
        return (Double(energy) / Double(distance)) * 100
    }
        
    static func totalDistance(trips: [Vehicle.DriveJournal.Trip]) -> Int { // In km
        return trips.reduce(0, { sum, trip in
            guard let _ = trip.detail else {
                return sum
            }
            return sum + trip.detail!.distance
        })
    }
    
    static func totalFuelConsumption(trips: [Vehicle.DriveJournal.Trip]) -> Int { // In deci liter
        return trips.reduce(0, { sum, trip in
            guard let _ = trip.detail else {
                return sum
            }
            return sum + (trip.detail!.fuelConsumption ?? EnergyEconomy.defaultFuellConsumption)
        })
    }

    
    static func totalElectricalConsumption(trips: [Vehicle.DriveJournal.Trip]) -> Int { // In km
        return trips.reduce(0, { sum, trip in
            guard let _ = trip.detail else {
                return sum
            }
            return sum + (trip.detail!.electricalConsumption ?? EnergyEconomy.defaultElectricalConsumption)
        })
    }

    static func totalPureDistance(trips: [Vehicle.DriveJournal.Trip]) -> Int { // In km
        return trips.reduce(0, { sum, trip in
            guard let _ = trip.detail, trip.detail!.isPureTrip else {
                return sum
            }
            return sum + trip.detail!.distance
        })
    }

    static func totalPureElectricalConsumption(trips: [Vehicle.DriveJournal.Trip]) -> Int { // In km
        return trips.reduce(0, { sum, trip in
            
            
            guard let _ = trip.detail, trip.detail!.isPureTrip else {
                return sum
            }
            return sum + (trip.detail!.electricalConsumption ?? EnergyEconomy.defaultElectricalConsumption)
        })
    }
    
    /// Share in % of Pure Distance to Total Distance driven
    /// - Parameter data: Array of trip
    /// - Returns: Share in %
    static func shareOfPureTrips(_ data: [Vehicle.DriveJournal.Trip]?) -> Double? {
        guard let _ = data else {
            return nil;
        }
        var pureDistance: Int = 0
        var totalDistance: Int = 0
        for trip in data! {
            guard let details = trip.detail else {
                continue
            }
            totalDistance += details.distance
            if details.fuelConsumption == 0 || details.fuelConsumption == nil {
                pureDistance += details.distance
            }
        }
        return Double(pureDistance) / Double(totalDistance)
    }
    
    
}
