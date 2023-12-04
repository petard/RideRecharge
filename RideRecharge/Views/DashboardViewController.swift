//
//  DashboardViewController.swift
//  CarRemote
//
//  Created by pluto on 31.10.20.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    @IBOutlet weak var statusContainer: UIView!
    @IBOutlet weak var timerBtn: UIButton!
    @IBOutlet weak var homeLocationBtn: UIButton!
    @IBOutlet weak var currentLocationBtn: UIButton!
    @IBOutlet weak var vehicleLocation: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var outsideTemp: UILabel!
    @IBOutlet weak var batteryTop: UILabel!
    @IBOutlet weak var batteryBottom: UILabel!
    @IBOutlet weak var fuelLevel: UILabel!
    @IBOutlet weak var fuelRemainingDistance: UILabel!
    
    @IBOutlet weak var batteryStatus: UIImageView!
    // Car Functions
    @IBAction func timerBtnTapped(_ sender: Any) {
        guard
            let vehicle = User.shared.vehicle,
            let heater = vehicle.status?.heater else {
            return
        }
        User.shared.vehicle?.setHeater(enabled: !heater.isEnabled) { [weak self] (error) in
            guard let self = self else {
                return;
            }
            var msg: String = "Heating is \(vehicle.status!.heater.isEnabled ? "on." : "off.")"
            if error != nil {
                msg = "An error occured. \(msg)"
            } else {
                DispatchQueue.main.async {
                    self.updateStatus(for: vehicle)
                    
                }
            }
            DispatchQueue.main.async {
                self.updateStatus(for: vehicle)
            }
        }
    }
    @IBOutlet weak var vehicleLockBtn: UIButton!
    @IBAction func vehicleLockBtnTapped(_ sender: Any) {
        guard let vehicle = User.shared.vehicle, let _ = vehicle.status else {
            return;
        }
        vehicle.carLocked(newState: !vehicle.status!.carLocked) { [weak self] (error) in
            
            guard let self = self else {
                return;
            }
            var msg: String = "Car is \(vehicle.status!.carLocked ? "locked." : "unlocked.")"
            if error != nil {
                msg = "An error occured. \(msg)"
            } else {
                DispatchQueue.main.async {
                    self.updateStatus(for: vehicle)
                    
                }
            }
            DispatchQueue.main.async {
                self.updateStatus(for: vehicle)
            }
        }
    }
    
    // Send to POI
    @IBOutlet weak var sendPOI: UIButton!
    
    @IBAction func sendPOITapped(_ sender: Any) {
        guard let _ = self.map.selectedAnnotations.first as? ChargeLocation else {
            return
        }
        self.handleSendPOIselected(annotation: (self.map.selectedAnnotations.first as! ChargeLocation))
    }
    
    
    // Locations
    @IBAction func currentLocationBtnTapped(_ sender: Any) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            map.setCenter(self.map.userLocation.coordinate, animated: true)
        case .notDetermined:
            self.manager.requestWhenInUseAuthorization()
            return;
        default:
            break;
        }
    }
    @IBAction func homeLocationBtnTapped(_ sender: Any) {
        guard let _ = User.shared.home else {
            return;
        }
        map.setCenter(User.shared.home!.coordinate, animated: true)
    }
    @IBAction func vehicleLocationBtnTapped(_ sender: Any) {
        guard let coordinate = User.shared.vehicle?.coordinate else {
            return;
        }
        map.setCenter(coordinate, animated: true)
    }
    
    private let manager = CLLocationManager()
        
    private var currentLocation: CLLocation?
    
    private var homeChargeLocationsLoaded: Bool = false
    
    // MKAppleLogoImageView
    // legalLabelInsets
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.registerMapAnnotationViews()
        self.manager.delegate = self
        self.sendPOI.isEnabled = false

        // update map when entering foreground
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [unowned self] notification in
            self.updateDataAndViews()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateDataAndViews()
    }
    
    private func updateDataAndViews() {
        
        self.updateHome()
        
        Vehicle.load { [weak self] (vehicle, error) in
            
            guard let self = self else {
                return
            }
            
            User.shared.vehicle = vehicle
            
            DispatchQueue.main.async {
                self.updateAnnotation(vehicle)
                self.updateStatus(for: vehicle)
                self.setInitialRect(vehicle?.coordinate ?? self.currentLocation?.coordinate ?? User.shared.home?.coordinate)
                self.showChargeLocations(around: vehicle?.coordinate)
                self.showChargeLocations(around: self.currentLocation?.coordinate)
            }
        }
    }
    
    private var homeAnnotation: MKAnnotation? {
        return self.map.annotations.first(where: { return $0.title == "Home" })
    }
    
    private func updateHome() {
        // setup home button
        
        if let oldHome = self.homeAnnotation {
            self.map.removeAnnotation(oldHome)
        }

        if let _ = User.shared.home  {
            self.map.addAnnotation(User.shared.home!)
            self.showChargeLocations(around: User.shared.home!.coordinate)
            self.homeLocationBtn.isEnabled = true
        } else {
            self.homeLocationBtn.isEnabled = false
        }
    }
    
    private func updateAnnotation(_ vehicle: Vehicle?) {
        
        if let oldHome = self.homeAnnotation {
            self.map.removeAnnotation(oldHome)
        }

        if let _ = vehicle {
            self.map.addAnnotation(vehicle!)
        }
        
    }
    
    private func setInitialRect(_ coordinate: CLLocationCoordinate2D?) {
        guard let _ = coordinate else {
            return;
        }
        
        let regionRadius: CLLocationDistance = 800
        let coordinateRegion = MKCoordinateRegion(
            center: coordinate!,
          latitudinalMeters: regionRadius,
          longitudinalMeters: regionRadius)
        map.setRegion(coordinateRegion, animated: false)
        map.setCenter(coordinate!, animated: false)
        
    }
    
    // MARK: Manage ChargeLocations
    
    private func handleSendPOIselected(annotation: ChargeLocation) {
        let a: ChargeLocation? = annotation.copy() as? ChargeLocation
        a?.title = annotation.subtitle
        a?.subtitle = annotation.title
        SendPOItoCar.Service.send([a ?? annotation]) { (error) in
            var msg: String = "Location sent to car successfully."
            if error != nil {
                debugPrint("SendPOItoCar failed \(error!)")
                msg = "Failed to sent location to car."
            }
            DispatchQueue.main.async {
                Toast.pop(message: msg, controller: self)
            }
        }
    }
    
    private func showChargeLocations(around coordinate: CLLocationCoordinate2D?) {
        
        guard let _ = coordinate else {
            return;
        }
        
        ChargeLocationServices.ENBW.nearBy(location: coordinate!) { [weak self] (locations, error) in
            guard
                let self = self,
                error == nil,
                let _ = locations
            else {
                return;
            }
            
            DispatchQueue.main.async {
                self.updateMap(with: locations!)
            }
        }
    }
    
    private func updateMap(with locations: [ChargeLocation]) {
        
        guard !locations.isEmpty else {
            return
        }
        
        let toBeAddedLocations = locations.filter { (location) -> Bool in
            let needsUpdateLocation = self.map.annotations.first { (annotation) -> Bool in
                guard let c = annotation as? ChargeLocation else {
                    return false
                }
                return c == location
            }
            // if the location exists update it, otherwise add it to the map
            return !self.updateMarker(for: needsUpdateLocation as? ChargeLocation)
        }
        
        self.map.addAnnotations(toBeAddedLocations)
        
    }
    
    private func updateMarker(for annotation: ChargeLocation?) -> Bool {
        guard
            let _ = annotation,
            let view = self.map.view(for: annotation!) as? MKMarkerAnnotationView else {
            return false
        }
        
        self.updateChargeLocationeAnnotationView(for: annotation!, on: view)
        return true
    }

    private func setStatusToDefault() {
        self.fuelLevel.text = "--%"
        self.fuelRemainingDistance.text = "--km"
        self.outsideTemp.text = "--C"
        self.batteryTop.text = "--%"
        self.batteryBottom.text = "--km"
        self.batteryStatus.tintColor = .label
        self.vehicleLockBtn.isEnabled = false
        self.timerBtn.isEnabled = false
        self.vehicleLocation.isEnabled = false
    }
    
    private func updateStatus(for vehicle: Vehicle?) {
        guard let _ = vehicle, let status = vehicle!.status, let attributes = vehicle!.attributes else {
            self.setStatusToDefault()
            return
        }
        
        self.vehicleLocation.isEnabled = true
        
        // lock status
        self.vehicleLockBtn.isEnabled = true
        self.vehicleLockBtn.isSelected = !status.carLocked
        
        // heater status
        self.timerBtn.isEnabled = attributes.remoteHeaterSupported || (attributes.preclimatizationSupported && status.remoteClimatizationStatus != Vehicle.Status.RemoteClimatization.noCableConnected.rawValue)
        self.timerBtn.isSelected = status.heater.isEnabled

        // fuel economy
        self.fuelLevel.text = "\(status.fuelAmountLevel)%"
        self.fuelRemainingDistance.text = "\(status.fueldistanceToEmpty)km"

        //weather
        WeatherService.load(location: vehicle!.coordinate) { (weather, error) in
            DispatchQueue.main.async {
                guard
                    let temp = weather?.observations.location.first?.observation.first?.temperature,
                    let double = Double(temp)
                else {
                    return;
                }
                self.outsideTemp.text = "\(Int(double))C"
            }
        }
        
        // battery
        guard let battery = status.battery, let charge = battery.chargeStatus else {
            return;
        }
        
        let batteryImage: UIImage? = UIImage(systemName: "bolt.fill")
        let distanceToEmptyKm: String = battery.distanceToEmptyKm == nil ? "--km" : "\(battery.distanceToEmptyKm!)km"
        
        switch charge {
        case .interrupted:
            self.batteryStatus.image = batteryImage
            self.batteryStatus.tintColor = .systemRed
            self.batteryTop.text = "\(battery.level)%"
            self.batteryBottom.text = distanceToEmptyKm
        case .started, .progress:
            self.batteryTop.text = battery.fullyChargedAtTime
            self.batteryBottom.text = battery.fullyChargedAtDay
            self.batteryStatus.image = batteryImage
            self.batteryStatus.tintColor = .systemGreen
        case .unplugged, .finished:
            self.batteryTop.text = "\(battery.level)%"
            self.batteryBottom.text = distanceToEmptyKm
            self.batteryStatus.image = batteryImage
            self.batteryStatus.tintColor = .label
        }
    }
    
    /// Register the annotation views with the `mapView` so the system can create and efficently reuse the annotation views.
    /// - Tag: RegisterAnnotationViews
    private func registerMapAnnotationViews() {
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(ChargeLocation.self))
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(Vehicle.self))
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

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            self.manager.requestLocation()
        default:
            break;
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    
}


extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("view selected", view)
        guard let _ = view.annotation as? ChargeENBWLocation else {
            return
        }
        
        self.sendPOI.isEnabled = true
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        self.sendPOI.isEnabled = false
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
           
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
        let identifier = NSStringFromClass(Vehicle.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            markerAnnotationView.animatesWhenAdded = false
            markerAnnotationView.canShowCallout = true
            markerAnnotationView.markerTintColor = UIColor.systemBlue
            markerAnnotationView.glyphImage = UIImage(systemName: "car")
            /*
             Add a detail disclosure button to the callout, which will open a new view controller or a popover.
             When the detail disclosure button is tapped, use mapView(_:annotationView:calloutAccessoryControlTapped:)
             to determine which annotation was tapped.
             If you need to handle additional UIControl events, such as `.touchUpOutside`, you can call
             `addTarget(_:action:for:)` on the button to add those events.
             */
        }
        
        return view
    }
    
    func updateChargeLocationeAnnotationView(for annotation: ChargeLocation, on markerAnnotationView: MKMarkerAnnotationView) {
        markerAnnotationView.animatesWhenAdded = false
        markerAnnotationView.canShowCallout = true
        markerAnnotationView.glyphImage = UIImage(systemName: "bolt.fill")
        // somehow changes to annotations title and subtitle are not observed
        if annotation.title != markerAnnotationView.annotation?.title {
            annotation.setValue(annotation.title, forKey: "title")
        }
        if annotation.title != markerAnnotationView.annotation?.subtitle {
            annotation.setValue(annotation.title, forKey: "subtitle")
        }
        
        switch annotation.availability {
        case .available:
            markerAnnotationView.markerTintColor = UIColor.systemGreen
            markerAnnotationView.alpha = 1
            break;
        case .occupied:
            markerAnnotationView.markerTintColor = UIColor.systemRed
            markerAnnotationView.alpha = 0.4
            break;
        case .unkown, .offline:
            markerAnnotationView.markerTintColor = UIColor.systemGray
            markerAnnotationView.alpha = 0.4
            break;
        }
    }

    
    /// Create an annotation view for charge locations, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    private func setupChargeLocationeAnnotationView(for annotation: ChargeLocation, on mapView: MKMapView) -> MKAnnotationView {
        let identifier = NSStringFromClass(ChargeLocation.self)
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier, for: annotation)
        if let markerAnnotationView = view as? MKMarkerAnnotationView {
            markerAnnotationView.canShowCallout = true
            updateChargeLocationeAnnotationView(for: annotation, on: markerAnnotationView)
            /*
             Add a detail disclosure button to the callout, which sends the location to the car navigation
             */

            let b = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            b.tintColor = .label
            b.setImage(UIImage(systemName: "arrow.right.circle"), for: .normal)
            b.imageView?.translatesAutoresizingMaskIntoConstraints = false
            b.imageView?.widthAnchor.constraint(equalToConstant: 30).isActive = true
            b.imageView?.heightAnchor.constraint(equalToConstant: 30).isActive = true
            markerAnnotationView.rightCalloutAccessoryView = b
        }
        
        return view
    }
    
    /// Called whent he user taps the send button in the charge annotation callout.
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        // This illustrates how to detect which annotation type was tapped on for its callout.
        if let annotation = view.annotation as? ChargeLocation {
            
            self.handleSendPOIselected(annotation: annotation)
            
        }
    }

}
