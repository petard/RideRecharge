//
//  MainMapViewController.swift
//  RideRecharge
//
//  Created by yuri on 11.08.22.
//

import UIKit
import MapKit
import CoreLocation

class MainMapViewController: UIViewController {
    
    static let storyboardIdentifier: String = String(describing: MainMapViewController.self)
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var mapActions: UIStackView!
    
    @IBAction func homeBtn(_ sender: Any) {
        guard let _ = User.shared.home else {
            alert(title: "Go to Home Location", message: "No home location set")
            return;
        }
        self.setVisibleRegion(center: User.shared.home!.coordinate)
    }
    
    @IBAction func userBtn(_ sender: Any) {
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            self.setVisibleRegion(center: self.map.userLocation.coordinate)
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return;
        default:
            break;
        }
    }
    
    @IBAction func carBtn(_ sender: Any) {
        guard let coordinate = User.shared.vehicle?.coordinate else {
            alert(title: "Go to Vehicle Location", message: "Vehicle location not available.")
            return;
        }
        self.setVisibleRegion(center: coordinate)
    }
    
    @IBOutlet weak var homeBtn: UIButton!
    

    @IBOutlet weak var carBtn: UIButton!
    
    @IBOutlet weak var userBtn: UIButton!
    
    private var carDetailVC: CarDetailsViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.registerMapAnnotationViews()
        NotificationCenter.default.addObserver(self, selector: #selector(updateDataAndViews), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        self.carDetailVC = self.storyboard?.instantiateViewController(withIdentifier: CarDetailsViewController.storyboardIdentifier) as? CarDetailsViewController
        
        self.homeBtn.configuration?.buttonSize = .mini
        self.carBtn.configuration?.buttonSize = .mini
        self.userBtn.configuration?.buttonSize = .mini
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.updateDataAndViews()

        // present info sheet
        guard self.presentedViewController == nil else {
            return;
        }
        carDetailVC.loadViewIfNeeded()
        present(carDetailVC, animated: true, completion: {
            DispatchQueue.main.async {
                NSLayoutConstraint.activate([
                    self.mapActions.bottomAnchor.constraint(equalTo: self.carDetailVC.view.topAnchor, constant: -40),
                    self.mapActions.trailingAnchor.constraint(equalTo: self.carDetailVC.view.trailingAnchor, constant: -10)
                ])
                self.mapActions.isHidden = false
            }
            
        })
    }
    
    /// Register the annotation views with the `mapView` so the system can create and efficently reuse the annotation views.
    /// - Tag: RegisterAnnotationViews
    private func registerMapAnnotationViews() {
        map.register(VehicleMarker.self, forAnnotationViewWithReuseIdentifier: VehicleMarker.reuseIdentifier)
        map.register(ChargeLocationActionMarker.self, forAnnotationViewWithReuseIdentifier: ChargeLocationActionMarker.reuseIdentifier)
    }
    
    private func alert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        DispatchQueue.main.async {
            if let vc = self.presentedViewController {
                vc.present(alertController, animated: true, completion: nil)
            } else {
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
        
    private func setVisibleRegion(center: CLLocationCoordinate2D) {
        
        /*
         There is no reason for users to zoom out to view entire countries and
         beyond, nor does the event map have enough details to make detailed
         zoom levels relevant. Apply a camera zoom range to restrict how far in
         and out users can zoom in the map view.
        */
        self.map.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 500,
                                                            maxCenterCoordinateDistance: 5000)
        
        /*
         To make sure users do not accidentally pan away from the event and get
         lost, apply a camera boundary. This ensures that the center point of
         the map always remain inside this region.
        */
        
        // The region that defines the camera boundary used in the event view.
        let cameraBoundary = MKCoordinateRegion(center:  center,
                                                       latitudinalMeters: 3000, longitudinalMeters: 3000)
        
        self.map.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: cameraBoundary)

        // set the map to center and zoom level
        map.setRegion(self.map.cameraBoundary!.region, animated: false)
        self.map.setCenter(center, animated: false)

        // load charging point for current camera boundaries
        
        Task {
            let locationsRect = try await ChargeLocationServices.TomTom.nearBy(location: center)
           // let locationsRect = try await ChargeLocationServices.ENBW.within(mapRect: self.map.cameraBoundary!.mapRect)
            let existingAnnotations = self.map.annotations.filter { return $0 is ChargeLocation }
            self.map.addAnnotations(locationsRect)
            self.map.removeAnnotations(existingAnnotations)
        }

    }
    
    // MARK: - Update View Data

    @objc func updateDataAndViews() {
        
        Task {
            do {
                let vehicle = try await Vehicle.load()
                
                // only change viewport if vehicle location changed
                if vehicle.coordinate != User.shared.vehicle?.coordinate {
                    self.setVisibleRegion(center: vehicle.coordinate)
                }
                
                User.shared.set(vehicle: vehicle)
                User.shared.vehicle?.journal = try? await Vehicle.DriveJournal.load()

                DispatchQueue.main.async {
                    let existingAnnotations = self.map.annotations.filter { return $0 is Vehicle }
                    self.map.removeAnnotations(existingAnnotations)
                    self.map.addAnnotation(vehicle)
                }
                
                await self.carDetailVC.updateUsing(vehicle: vehicle)

            } catch {
                DispatchQueue.main.async {
                    self.alert(title: "Error", message: error.localizedDescription)
                    //self.setInitialRect(self.currentLocation?.coordinate ?? User.shared.home?.coordinate)
                }
            }
            
        }
        
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MainMapViewController: MKMapViewDelegate {
    
  
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // only load charging points when zoom level is close
        guard mapView.region.span.latitudeDelta < 0.05, mapView.region.span.longitudeDelta < 0.05 else {
            return;
        }
        Task {
            //try? await self.showChargeLocations(around: map.region.center)
        }
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let annotations = self.map.annotations(in: self.map.visibleMapRect)
        
        for annotation in annotations {
            if let charger = annotation as? ChargeLocation, charger.postalAddress == nil {
                
                Task {
                    let address = try? await GeoLookupService.location(coordinates: charger.coordinate)
                    charger.postalAddress = address
                }
            }
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKind(of: MKUserLocation.self) else {
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        if let annotation = annotation as? Vehicle {
            annotationView = setupVehicleAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? ChargeLocation {
            annotationView = setupChargeLocationeAnnotationView(for: annotation, on: mapView)
        }
        return annotationView
    }
    
    /// Create an annotation view for vehicle location, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    private func setupVehicleAnnotationView(for annotation: Vehicle, on mapView: MKMapView) -> MKAnnotationView {
        
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: VehicleMarker.reuseIdentifier, for: annotation) as! VehicleMarker
        view.set(vehicle: annotation)
        return view
    }
    
    /// Create an annotation view for charge locations, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    private func setupChargeLocationeAnnotationView(for annotation: ChargeLocation, on mapView: MKMapView) -> MKAnnotationView {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: ChargeLocationActionMarker.reuseIdentifier, for: annotation) as! ChargeLocationActionMarker
        view.set(location: annotation)
        return view
    }
    
    /// Called whent he user taps the send button in the charge annotation callout.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // This illustrates how to detect which annotation type was tapped on for its callout.
        guard
            let annotation = view.annotation as? ChargeLocation,
            let view = view as? ChargeLocationActionMarker
        else
         {
            return;
        }
        
        guard !SendPOItoCar.Service.isSending() else {
            return
        }
        
        view.isSending = true
        Task {
            do {
                try await SendPOItoCar.Service.send([annotation])
                DispatchQueue.main.async {
                    view.isSending = false
                }
            } catch {
                debugPrint("SendPOItoCar failed \(error)")
                DispatchQueue.main.async {
                    view.isSending = false
                    self.alert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
}
