//
//  TestData.swift
//  RideRecharge
//
//  Created by pluto on 22.01.21.
//

import Foundation
import MapKit

class TestData {
    static var userHome: MKPointAnnotation {
        let home = MKPointAnnotation()
        home.title = "Your home"
        home.subtitle = "Street"
        home.coordinate = CLLocationCoordinate2D(latitude: 50.935735311966866, longitude: 6.943091009428059)
        return home
    }
    
    static let vehiclePosition: String = """
    {
      "position": {
        "longitude": 6.946293566872339,
        "latitude": 50.93556628108629,
        "timestamp": "2020-11-05T11:45:43+0000",
        "speed": null,
        "heading": null
      },
      "calculatedPosition": {
        "longitude": null,
        "latitude": null,
        "timestamp": "2020-10-19T08:05:12+0000",
        "speed": null,
        "heading": null
      }
    }
    """
    
    static let vehicleStatus = """
    {
      "ERS": {
        "status": null,
        "timestamp": null,
        "engineStartWarning": null,
        "engineStartWarningTimestamp": null
      },
      "averageFuelConsumption": 65.0,
      "averageFuelConsumptionTimestamp": "2020-12-30T18:30:22+0000",
      "averageSpeed": 35,
      "averageSpeedTimestamp": "2020-12-30T18:30:22+0000",
      "brakeFluid": "Normal",
      "brakeFluidTimestamp": "2020-12-30T18:30:22+0000",
      "bulbFailures": [],
      "bulbFailuresTimestamp": "2020-12-30T18:30:22+0000",
      "carLocked": true,
      "carLockedTimestamp": "2020-12-30T18:30:22+0000",
      "connectionStatus": "ConnectedWithPower",
      "connectionStatusTimestamp": "2020-12-30T21:21:40+0000",
      "distanceToEmpty": 370,
      "distanceToEmptyTimestamp": "2020-12-30T18:30:22+0000",
      "doors": {
        "tailgateOpen": false,
        "rearRightDoorOpen": false,
        "rearLeftDoorOpen": false,
        "frontRightDoorOpen": false,
        "frontLeftDoorOpen": false,
        "hoodOpen": false,
        "timestamp": "2020-12-30T18:30:22+0000"
      },
      "engineRunning": false,
      "engineRunningTimestamp": "2020-12-30T18:30:22+0000",
      "fuelAmount": 51,
      "fuelAmountLevel": 72,
      "fuelAmountLevelTimestamp": "2020-12-30T18:30:22+0000",
      "fuelAmountTimestamp": "2020-12-30T18:30:22+0000",
      "heater": {
        "seatSelection": {
          "frontDriverSide": false,
          "frontPassengerSide": false,
          "rearDriverSide": false,
          "rearPassengerSide": false,
          "rearMid": false
        },
        "status": "off",
        "timer1": {
          "time": null,
          "state": null
        },
        "timer2": {
          "time": null,
          "state": null
        },
        "timestamp": "2020-12-19T19:34:13+0000"
      },
      "hvBattery": {
        "hvBatteryChargeStatusDerived": "CablePluggedInCar_FullyCharged",
        "hvBatteryChargeStatusDerivedTimestamp": "2020-12-30T21:21:40+0000",
        "hvBatteryChargeModeStatus": null,
        "hvBatteryChargeModeStatusTimestamp": null,
        "hvBatteryChargeStatus": "ChargeEnd",
        "hvBatteryChargeStatusTimestamp": "2020-12-30T21:21:40+0000",
        "hvBatteryLevel": 100,
        "hvBatteryLevelTimestamp": "2020-12-30T21:21:40+0000",
        "distanceToHVBatteryEmpty": 35,
        "distanceToHVBatteryEmptyTimestamp": "2020-12-30T21:21:40+0000",
        "hvBatteryChargeWarning": "UnexpectedPowerloss",
        "hvBatteryChargeWarningTimestamp": "2020-12-13T15:14:56+0000",
        "timeToHVBatteryFullyCharged": 0,
        "timeToHVBatteryFullyChargedTimestamp": "2020-12-30T21:21:40+0000"
      },
      "odometer": 1944169,
      "odometerTimestamp": "2020-12-30T18:30:22+0000",
      "privacyPolicyEnabled": false,
      "privacyPolicyEnabledTimestamp": "2020-10-13T11:20:03+0000",
      "remoteClimatizationStatus": "CableConnectedWithPower",
      "remoteClimatizationStatusTimestamp": "2020-12-30T21:21:40+0000",
      "serviceWarningStatus": "Normal",
      "serviceWarningStatusTimestamp": "2020-12-30T18:30:22+0000",
      "theftAlarm": null,
      "timeFullyAccessibleUntil": "2021-01-04T18:21:59+0000",
      "timePartiallyAccessibleUntil": "2021-01-21T18:21:59+0000",
      "tripMeter1": 1928100,
      "tripMeter1Timestamp": "2020-12-30T18:30:22+0000",
      "tripMeter2": 6500,
      "tripMeter2Timestamp": "2020-12-30T18:30:22+0000",
      "tyrePressure": {
        "frontLeftTyrePressure": "Normal",
        "frontRightTyrePressure": "Normal",
        "rearLeftTyrePressure": "Normal",
        "rearRightTyrePressure": "Normal",
        "timestamp": "2020-12-30T18:30:22+0000"
      },
      "washerFluidLevel": "Normal",
      "washerFluidLevelTimestamp": "2020-12-30T18:30:22+0000",
      "windows": {
        "frontLeftWindowOpen": false,
        "frontRightWindowOpen": false,
        "timestamp": "2020-12-30T18:30:22+0000",
        "rearLeftWindowOpen": false,
        "rearRightWindowOpen": false
      }
    }
    """
    static let vehicleAttributes = """
    {
      "engineCode": "2421CF30",
      "exteriorCode": "24211104",
      "interiorCode": "24211015",
      "tyreDimensionCode": "2421R507",
      "tyreInflationPressureLightCode": null,
      "tyreInflationPressureHeavyCode": null,
      "gearboxCode": "2421DB01",
      "fuelType": "HEV",
      "fuelTankVolume": 70,
      "grossWeight": 2460,
      "modelYear": 2020,
      "vehicleType": "XC60",
      "vehicleTypeCode": "2223F05",
      "numberOfDoors": 5,
      "country": {
        "iso2": "DE"
      },
      "registrationNumber": "K-VO-1900E",
      "carLocatorDistance": 1000,
      "honkAndBlinkDistance": 500,
      "bCallAssistanceNumber": "+4989208018742",
      "carLocatorSupported": true,
      "honkAndBlinkSupported": true,
      "honkAndBlinkVersionsSupported": [
        "honkAndOrBlink",
        "honkAndBlink"
      ],
      "remoteHeaterSupported": false,
      "unlockSupported": true,
      "lockSupported": true,
      "journalLogSupported": true,
      "assistanceCallSupported": true,
      "unlockTimeFrame": 120,
      "verificationTimeFrame": 120,
      "timeFullyAccessible": 7200,
      "timePartiallyAccessible": 31680,
      "subscriptionType": "PREMIUM_2013",
      "subscriptionStartDate": "2019-1-16T00:00:00+0000",
      "subscriptionEndDate": "2022-1-16T00:00:00+0000",
      "serverVersion": "20.6.32-voc-deployable",
      "VIN": "MADEINSWEDEN",
      "journalLogEnabled": true,
      "highVoltageBatterySupported": true,
      "maxActiveDelayChargingLocations": 7,
      "preclimatizationSupported": true,
      "sendPOIToVehicleVersionsSupported": [
        "sendSinglePOIToVehicle"
      ],
      "climatizationCalendarVersionsSupported": [
        "climatizationCalendarV1"
      ],
      "climatizationCalendarMaxTimers": 8,
      "vehiclePlatform": "2321",
      "vin": "MADEINSWEDEN",
      "overrideDelayChargingSupported": true,
      "engineStartSupported": false,
      "status.parkedIndoor.supported": false
    }
    """
    
    static let vehicleDriveJournal: String = """
    {
      "trips": []
    }
    """
    
    static let customerAccount: String = """
    {
      "username": "your@email.com",
      "firstName": "Max",
      "lastName": "Headroom",
      "accountId": "XXXXXXXXXX",
      "account": "https://vocapi.wirelesscar.net/customerapi/rest/v3.0/customeraccounts/XXXXXXXXX",
      "accountVehicleRelations": [
        "https://vocapi.wirelesscar.net/customerapi/rest/v3.0/vehicle-account-relations/323232323"
      ]
    }
    """
    
    static let customerAccountVehicleRelations: String = """
    {
      "account": "https://vocapi.wirelesscar.net/customerapi/rest/v3.0/customeraccounts/XXXXXXXXX",
      "accountId": "XXXXXXXXX",
      "vehicle": "https://vocapi.wirelesscar.net/customerapi/rest/v3.0/vehicles/XXXXXXXXX",
      "accountVehicleRelation": "https://vocapi.wirelesscar.net/customerapi/rest/v3.0/vehicle-account-relations/XXXXXXXXX",
      "vehicleId": "XXXXXXXXX",
      "username": "your@email.com",
      "status": "Verified",
      "customerVehicleRelationId": 323232323
    }
    """
    
}

