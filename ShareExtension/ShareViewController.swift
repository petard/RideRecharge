//
//  ShareViewController.swift
//  Send Location
//
//  Created by pluto on 21.10.20.
//

import UIKit
import Foundation
import MapKit

class ShareViewController: UIViewController {
    
    @IBAction func cancelBtnTapped(_ sender: Any) {
        URLSession.shared.invalidateAndCancel()
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: {_ in
            self.map = nil
        })
    }
    
    @IBOutlet weak var sendToCarBtn: UIButton!
    
    @IBAction func sendToCarBtnTapped(_ sender: Any) {
        
        let mainAppName: String = "RideRecharge"
        
        guard !SendPOItoCar.Service.isSending() else {
            return
        }
        
        guard
            let selectedAnnotation = self.map.selectedAnnotations.first
        else {
            self.alert(title: "Missing Location", message: "Please select a location on the map before sending.")
            return;
        }
        
        guard
            canSendLocation()
        else {
            alert(title: "Authentication Error", message: "Please verfiy your Volvo On Call settings in the \(mainAppName) app.")
            return;
        }
        
        self.isSending = true
                
        Task {
            do {
                try await SendPOItoCar.Service.send([selectedAnnotation])
                self.isSending = false
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
            catch ServiceError.authenticationFailed {
                self.isSending = false
                alert(title: "Authentication Error", message: "Please verfiy your Volvo On Call username and password in the \(mainAppName) app.")
            }
            catch {
                self.isSending = false
                self.alert(title: "Error", message: error.localizedDescription)
            }
            
        }
        
    }
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var errorTitleLabel: UILabel!
    @IBOutlet weak var errorDescriptonLabel: UILabel!
    
    struct StatusError: Error {
        enum ErrorKind: String {
            case readContext = "Unknown map data. Try Apple Maps or Google Maps."
            case unknown
            case handleGoogleContext = "Unable to read Google Maps data. Try different location or use Apple Maps."
            case handleAppleContext = "Unable to read Apple Maps data. Try different location or use Google Maps."
        }

        let kind: ErrorKind
    }
        
    private enum titleState: String {
        case normal = "Select destination"
        case sending = "Contacting car..."
    }
    
    private enum contentType: String {
        case plainText = "public.plain-text" // kUTTypePlainText as String
        case vCard = "public.vcard"
        case url = "public.url"
        case mapItem = "com.apple.mapkit.map-item"
    }
    
    private var poi: POI?
    
    private var isSending: Bool = false {
        didSet {
            if isSending {
                DispatchQueue.main.async {
                    self.titleLabel.text = titleState.sending.rawValue
                    self.sendToCarBtn.configuration?.showsActivityIndicator = true
                    self.sendToCarBtn.configuration?.imagePadding = 5
                }
            } else {
                DispatchQueue.main.async {
                    self.titleLabel.text = titleState.normal.rawValue
                    self.sendToCarBtn.configuration?.showsActivityIndicator = false
                }

            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _ = User.shared
        let _ = VOC.shared
        
        self.registerMapAnnotationViews()
        self.backgroundView.layer.cornerRadius = 10
        self.backgroundView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        Task {
            do {
                let poi = try await self.readContext()
                // Configure user location
                self.configureMap(destination: poi)
            } catch (let description) {
                self.setErrorNotification(title: "Something went wrong", description: description.localizedDescription)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Low memory detected")
        self.map?.mapType = .mutedStandard
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setErrorNotification(title: String, description: String) {
        DispatchQueue.main.async {
            self.errorTitleLabel.isHidden = false
            self.errorDescriptonLabel.isHidden = false
            self.errorTitleLabel.text = title
            self.errorDescriptonLabel.text = description
            self.map.isHidden = true
            self.sendToCarBtn.isEnabled = false
        }
    }
    
    private func alert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: Handle Toast
    private func canSendLocation() -> Bool {
        if User.shared.credentials == nil || User.shared.isTestUser {
            return false;
        }
        return true;
    }
    
    // MARK: Map
    
    private func configureMap(destination: POI) {
        // Center Map
        //let regionRadius: CLLocationDistance = 500 // Meter
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else {
                return
            }
            self.map.isHidden = false
            // clear user annotations
            let annotations = self.map.annotations.filter({ !($0 is MKUserLocation) })
            self.map.removeAnnotations(annotations)
            
            // configure map
            self.map.cameraZoomRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: 250,
                                                                 maxCenterCoordinateDistance: 7000)
            
            let cameraBoundary = MKCoordinateRegion(center:  destination.coordinate,
                                                    latitudinalMeters: 800, longitudinalMeters: 800)
            
            self.map.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: cameraBoundary)
            
            self.map.setCenter(destination.coordinate, animated: false)
            self.map.setRegion(self.map.cameraBoundary!.region, animated: false)
            
            
            // add POI annotation
            
            self.map.addAnnotation(destination)
            self.map.selectAnnotation(destination, animated: false)
            
            // load charging point for current camera boundaries
            Task {
                //  let chargers = try await ChargeLocationServices.ENBW.nearBy(location: self.map.centerCoordinate, distanceInMeter: 2000)
                // let chargers = try await ChargeLocationServices.ENBW.within(mapRect: self.map.cameraBoundary!.mapRect)
                let chargers = try await ChargeLocationServices.TomTom.nearBy(location: destination.coordinate)
                self.map.addAnnotations(chargers)
            }
            
        }
        
    }
    
    /// Register the annotation views with the `mapView` so the system can create and efficently reuse the annotation views.
    /// - Tag: RegisterAnnotationViews
    private func registerMapAnnotationViews() {
        map.register(POIMarker.self, forAnnotationViewWithReuseIdentifier: POIMarker.reuseIdentifier)
        map.register(VehicleMarker.self, forAnnotationViewWithReuseIdentifier: VehicleMarker.reuseIdentifier)
        map.register(ChargeLocationMarker.self, forAnnotationViewWithReuseIdentifier: ChargeLocationMarker.reuseIdentifier)
    }

    private func readContext() async throws -> POI {
        
        guard let itemProviders = (extensionContext?.inputItems.first as? NSExtensionItem)?.attachments else {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            throw ShareViewController.StatusError(kind: .readContext)

        }
        
        // check first if apple maps
        if let appleProvider = (itemProviders.first {$0.hasItemConformingToTypeIdentifier(contentType.mapItem.rawValue)}) {
            let data = try await appleProvider.loadItem(forTypeIdentifier: contentType.mapItem.rawValue, options: nil)
            guard
                let d = data as? Data,
             //   let mapItem = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(d) as? MKMapItem,
                let mapItem = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [MKMapItem.self], from: d) as? MKMapItem
            else {
                throw ShareViewController.StatusError(kind: .readContext)
            }
            return POI(place: mapItem.placemark)
        }
        
        // check if google maps
        if let googleProvider = (itemProviders.first {$0.hasItemConformingToTypeIdentifier(contentType.url.rawValue)}) {
            let data = try await googleProvider.loadItem(forTypeIdentifier: contentType.url.rawValue, options: nil)
            if let url = data as? URL {
                let poi = try await handleGoogleContext(url: url)
                return poi
            }
        }
        
        // unknown itemProviders
        throw ShareViewController.StatusError(kind: .readContext)

        
    }
    
    /// Beautify the query parameter in a Google Maps url
    /// - Parameter query: Content from q parameter in Google Maps url
    /// - Returns: Formatted query
    private func formatQuery(query: String?) -> String? {
        if
            let endOfSentence = query?.firstIndex(of: ","),
            let endOfQuery = query?.index(endOfSentence, offsetBy: -1) {
            let formattedQuery = query?[...endOfQuery].replacingOccurrences(of: "+", with: " ", options: .literal, range: nil)
            return formattedQuery
        }
        return nil
    }
    
    private func handleGoogleContext(url: URL) async throws -> POI {
        var request = URLRequest(url: url)
        request.httpShouldHandleCookies = false
        let (_, urlresponse) = try await URLSession.shared.data(for: request, delegate: self)
        
        guard
            let rawAbsoluteURL = (urlresponse as? HTTPURLResponse)?.value(forHTTPHeaderField: "Location"),
            let locationUrl = URL(string: rawAbsoluteURL)
        else {
            throw ShareViewController.StatusError(kind: .readContext)
        }
        
        let place = try await GooglePlaceServices.details.using(url: locationUrl)
        let coordinates: Coordinates = Coordinates(coordinate: place.geometry.coordinates)
        let query = self.formatQuery(query: GooglePlaceServices.search.query(from: locationUrl))
        
        let address = place.address ?? coordinates.string
        let name = place.name ?? query ?? "Dropped pin"
        return POI(title: name, position: coordinates, subtitle: address)
    }
    
}

extension ShareViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !annotation.isKind(of: MKUserLocation.self) else {
            // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
            return nil
        }
        
        var annotationView: MKAnnotationView?
        
        if let annotation = annotation as? ChargeLocation {
            annotationView = setupChargeLocationeAnnotationView(for: annotation, on: mapView)
        } else if let annotation = annotation as? POI {
            annotationView = setupPOIAnnotationView(for: annotation, on: mapView)
        }
        
        return annotationView
    }
    
    /// Create an annotation view for the point of initerest from the Map app, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    private func setupPOIAnnotationView(for annotation: POI, on mapView: MKMapView) -> MKAnnotationView {
        return mapView.dequeueReusableAnnotationView(withIdentifier: POIMarker.reuseIdentifier, for: annotation)
    }
    
    
    /// Create an annotation view for charge locations, customize the color, and add a button to the callout.
    /// - Tag: CalloutButton
    private func setupChargeLocationeAnnotationView(for annotation: ChargeLocation, on mapView: MKMapView) -> MKAnnotationView {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: ChargeLocationMarker.reuseIdentifier, for: annotation) as! ChargeLocationMarker
        view.set(location: annotation)
        return view
    }
}

extension ShareViewController: URLSessionDelegate, URLSessionTaskDelegate{
    
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
    
}
