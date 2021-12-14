//
//  ViewController.swift
//  Matta5
//
//  Created by Che Blankenship on 1/11/21.
//

import UIKit
import CoreLocation
import GoogleMaps
import GooglePlaces
import SwiftMQTT
import MessageUI


struct States {
    // travelModePickerView Visible/Invisible
    var setDestinationBtnClickable = false
    var travelModePicked = false
}

struct MqttConfigData {
    
    let mqttHost: String?
    let mqttClientId: String?
    let mqttPort:UInt16?
    
    init(host: String, clientId: String, port: UInt16) {
        mqttHost = host
        mqttClientId = clientId
        mqttPort = port
    }
    
}

struct LocationData {
    // Start
    var startInCoordinate: CLLocationCoordinate2D?
    var startInName: String?
    // End
    var destinationInCoordinate: CLLocationCoordinate2D?
    var destinationInName: String?
    // Indicators
    var reCentered: Bool = false
    // Travel mode
    let travelModesArr: [String] = ["driving", "walking", "bicycling", "transit"]
    var selectedTravelMode: String = "walking"
    // Key
    let key: String = "AIzaSyBA29cz4IQXbAQB5Bww4EHrk_0FG8hiGaM"
    // Pin usage
    var usePinForCoordinateSelection: Bool = false
}


class ViewController: UIViewController {
    
    // States
    var travelModePicked = States().travelModePicked
    var usePinForCoordinateSelection = LocationData().usePinForCoordinateSelection
    
    // Const
    let apiKey: String = LocationData().key
    let travelModes: [String] = LocationData().travelModesArr
    let mqttConfigData = MqttConfigData(host: "broker.emqx.io", clientId: "ios-app-" + UUID().uuidString, port: 1883)
    
    // Config data
    var startInCoordinate: CLLocationCoordinate2D? = LocationData().startInCoordinate
    var destinationInCoordinate: CLLocationCoordinate2D? = LocationData().destinationInCoordinate
    var destinationInName: String? = LocationData().destinationInName
    var selectedTravelMode: String = LocationData().selectedTravelMode // `walking` is the default mode
    var setDestinationBtnClickable: Bool = States().setDestinationBtnClickable // `false` is default
    
    // CLLocation
    private var locationManager: CLLocationManager?
    
    // Mqtt
    var mqttSession: MQTTSession!
    var currentLat: CLLocationDegrees? // Every time the location updates, this will hold the new location latitude
    var currentLng: CLLocationDegrees? // Every time the location updates, this will hold the new location longnitude
    
    // Map
    var mapView = GMSMapView()
    var reCenteredInitMap: Bool = LocationData().reCentered // This will turn true when mapview open and re-center to user location.
    
    // Message UI
    let composeVC = MFMessageComposeViewController()
    
    // ---------------------- General Views  ---------------------- //
    let travelModeBtn: UIButton = {
        let btn = UIButton()
        btn.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width / 1.2, height: UIScreen.main.bounds.size.height/17)
        btn.center = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height - (UIScreen.main.bounds.size.height/10)*3)
        btn.backgroundColor = .white
        btn.setTitle("Set Travel Mode", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 5
        btn.layer.shadowOffset = CGSize(width: 3, height: 3 )
        btn.layer.shadowOpacity = 0.8
        btn.layer.shadowRadius = 10
        btn.layer.shadowColor = UIColor.darkGray.cgColor
        btn.addTarget(self, action: #selector(setTravelModeBtnClicked), for: .touchUpInside)
        return btn
    }()
    
    //
    let setDestinationBtn: UIButton = {
        let btn = UIButton()
        btn.frame = CGRect(x: 0, y: 0, width: (UIScreen.main.bounds.size.width/10)*5, height: UIScreen.main.bounds.size.height/17)
        btn.center = CGPoint(x: (UIScreen.main.bounds.size.width/10)*3.5, y: UIScreen.main.bounds.size.height-(UIScreen.main.bounds.size.height/10)*2)
        btn.backgroundColor = .white
        btn.setTitle("Search Destination", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 5
        btn.layer.shadowOffset = CGSize(width: 3, height: 3 )
        btn.layer.shadowOpacity = 0.8
        btn.layer.shadowRadius = 10
        btn.layer.shadowColor = UIColor.darkGray.cgColor
        btn.addTarget(self, action: #selector(autocompleteClicked), for: .touchUpInside)
        return btn
    }()
    
    // Set destination with pin button
    let setDestinationWithPinBtn: UIButton = {
        let btn = UIButton()
        btn.frame = CGRect(x: 0, y: 0, width: (UIScreen.main.bounds.size.width/10)*2.5, height: UIScreen.main.bounds.size.height/17)
        btn.center = CGPoint(x: (UIScreen.main.bounds.size.width/10)*7.5, y: UIScreen.main.bounds.size.height-(UIScreen.main.bounds.size.height/10)*2)
        btn.backgroundColor = UIColor.init(cgColor: CGColor(red: 32/255, green: 178/255, blue: 170/255, alpha: 1))
        btn.setTitle("Use map", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 5
        btn.layer.shadowOffset = CGSize(width: 3, height: 3 )
        btn.layer.shadowOpacity = 0.8
        btn.layer.shadowRadius = 10
        btn.layer.shadowColor = UIColor.darkGray.cgColor
        btn.addTarget(self, action: #selector(pinOptionSelected), for: .touchUpInside)
        return btn
    }()
    
    // Pin location confirm button
    let confirmPinLocationBtn: UIButton = {
        let btn = UIButton()
        btn.frame = CGRect(x: 0, y: 0, width: (UIScreen.main.bounds.size.width/10)*2.5, height: UIScreen.main.bounds.size.height/17)
        btn.center = CGPoint(x: (UIScreen.main.bounds.size.width/10)*7.5, y: UIScreen.main.bounds.size.height-(UIScreen.main.bounds.size.height/10)*2)
        btn.backgroundColor = .orange
        btn.setTitle("Confirm", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 5
        btn.layer.shadowOffset = CGSize(width: 3, height: 3 )
        btn.layer.shadowOpacity = 0.8
        btn.layer.shadowRadius = 10
        btn.layer.shadowColor = UIColor.darkGray.cgColor
        btn.addTarget(self, action: #selector(pinCoordinateConfirmed), for: .touchUpInside)
        return btn
    }()
    
    // Share travel with others button
    let shareBtn: UIButton = {
        let btn = UIButton()
        btn.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width / 1.2, height: UIScreen.main.bounds.size.height/17)
        btn.center = CGPoint(x: UIScreen.main.bounds.size.width / 2, y: UIScreen.main.bounds.size.height - (UIScreen.main.bounds.size.height/10)*1)
        btn.backgroundColor = .black
        btn.setTitle("Start", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 5
        btn.layer.shadowOffset = CGSize(width: 3, height: 3 )
        btn.layer.shadowOpacity = 0.8
        btn.layer.shadowRadius = 10
        btn.layer.shadowColor = UIColor.darkGray.cgColor
        btn.addTarget(self, action: #selector(displayMessageInterface), for: .touchUpInside)
        return btn
    }()
    
    // Re-center button
    let reCenterBtn: UIButton = {
        let btn = UIButton()
        let currentLocationImg = UIImage(named:"currentLocation")!
        btn.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        btn.center = CGPoint(x: (UIScreen.main.bounds.size.width/8)*7, y: UIScreen.main.bounds.size.height - (UIScreen.main.bounds.size.height/10)*4)
        btn.backgroundColor = .white
        btn.setImage(currentLocationImg, for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.layer.cornerRadius = 25
        btn.layer.shadowOffset = CGSize(width: 3, height: 3 )
        btn.layer.shadowOpacity = 0.8
        btn.layer.shadowRadius = 10
        btn.layer.shadowColor = UIColor.darkGray.cgColor
        btn.addTarget(self, action: #selector(recenterMap), for: .touchUpInside)
        return btn
    }()
    
    
    // Travel Mode Picker View
    var travelModePickerView: UIView = {
        // Frame
        let screenWidth = CGFloat(UIScreen.main.bounds.width)
        let screenHeight = CGFloat(UIScreen.main.bounds.height)
        let container = UIView()
        container.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        container.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        return container
    }()
    
    // walking btn
    let walkingBtn: UIButton = {
        // Frame
        let screenWidth = CGFloat(UIScreen.main.bounds.width)
        let screenHeight = CGFloat(UIScreen.main.bounds.height)
        let btn = UIButton()
        btn.frame = CGRect(x: (screenWidth-(screenWidth/2))/2, y: (screenHeight/8)*2, width: (screenWidth)/2, height: screenHeight/17)
        btn.backgroundColor = .systemIndigo
        btn.setTitle("Walking", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(setToWalkingMode), for: .touchUpInside)
        return btn
    }()
    
    // driving btn
    let drivingingBtn: UIButton = {
        // Frame
        let screenWidth = CGFloat(UIScreen.main.bounds.width)
        let screenHeight = CGFloat(UIScreen.main.bounds.height)
        let btn = UIButton()
        btn.frame = CGRect(x: (screenWidth-(screenWidth/2))/2, y: (screenHeight/8)*3, width: (screenWidth)/2, height: screenHeight/17)
        btn.backgroundColor = .systemIndigo
        btn.setTitle("Driving", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(setToDrivingMode), for: .touchUpInside)
        return btn
    }()
    
    // biking btn
    let bikingBtn: UIButton = {
        // Frame
        let screenWidth = CGFloat(UIScreen.main.bounds.width)
        let screenHeight = CGFloat(UIScreen.main.bounds.height)
        let btn = UIButton()
        btn.frame = CGRect(x: (screenWidth-(screenWidth/2))/2, y: (screenHeight/8)*4, width: (screenWidth)/2, height: screenHeight/17)
        btn.backgroundColor = .systemIndigo
        btn.setTitle("Biking", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(setToBikingMode), for: .touchUpInside)
        return btn
    }()
    
    // transit btn
    let transitBtn: UIButton = {
        // Frame
        let screenWidth = CGFloat(UIScreen.main.bounds.width)
        let screenHeight = CGFloat(UIScreen.main.bounds.height)
        let btn = UIButton()
        btn.frame = CGRect(x: (screenWidth-(screenWidth/2))/2, y: (screenHeight/8)*5, width: (screenWidth)/2, height: screenHeight/17)
        btn.backgroundColor = .systemIndigo
        btn.setTitle("Transit", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(setToTransitMode), for: .touchUpInside)
        return btn
    }()
    
    // confirm btn
    let confirmBtn: UIButton = {
        // Frame
        let screenWidth = CGFloat(UIScreen.main.bounds.width)
        let screenHeight = CGFloat(UIScreen.main.bounds.height)
        let btn = UIButton()
        btn.frame = CGRect(x: (screenWidth-(screenWidth/2))/2, y: (screenHeight/8)*6, width: (screenWidth)/2, height: screenHeight/17)
        btn.backgroundColor = .white
        btn.setTitle("Confirm", for: .normal)
        btn.setTitleColor(.systemIndigo, for: .normal)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(confirmBtnClicked), for: .touchUpInside)
        return btn
    }()
    
    // Pin image for picking location
    let pinImg: UIImageView = {
        // Frame
        let screenWidth = CGFloat(UIScreen.main.bounds.width)
        let screenHeight = CGFloat(UIScreen.main.bounds.height)
        
        let img: UIImage = UIImage(named: "coordinate-pin")!
        let imgView = UIImageView(image: img)
        imgView.frame = CGRect(x: 0, y: 0, width: 30, height: 100)
        imgView.center = CGPoint(x: screenWidth/2, y: screenHeight/2)
        return imgView
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ---------------------- MQTT configurations  ---------------------- //
        mqttConfig(host: mqttConfigData.mqttHost!, port: mqttConfigData.mqttPort!, clientId: mqttConfigData.mqttClientId!)
        self.mqttSession.delegate = self
        establishConnection()
        
        // ---------------------- Location Manager configurations  ---------------------- //
        locationManager = CLLocationManager()
//        if locationManager?.authorizationStatus != .authorizedAlways || locationManager?.authorizationStatus != .authorizedWhenInUse {
//            locationManager?.requestAlwaysAuthorization()
//        }
        locationManager?.requestAlwaysAuthorization()
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.distanceFilter = 6  // Filter out the distance so it does not eat up battery/cpu usage
        locationManager?.startUpdatingLocation()
        
        // ---------------------- Map setup ---------------------- //
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        view = mapView
        reCenteredInitMap = false // initially set to false
        usePinForCoordinateSelection = false
        mapView.delegate = self
        
        // ---------------------- Message  ---------------------- //
        composeVC.messageComposeDelegate = self
        
        // ---------------------- General View Configurations ---------------------- //
        // Pin
        view.addSubview(pinImg)
        
        // Destination Setting Button
        view.addSubview(setDestinationBtn)
        disableBtn(btn: setDestinationBtn) // keep it disable until travel mode is set.
        
        
        // Pin Button for setting destination
        view.addSubview(setDestinationWithPinBtn)
        disableBtn(btn: setDestinationWithPinBtn)
        
        // Confirm Pin location button
        view.addSubview(confirmPinLocationBtn)
        hideBtn(btn: confirmPinLocationBtn)
        
        // Share Button
        view.addSubview(shareBtn)
        disableBtn(btn: shareBtn) // keep it disable until destination is set.
        
        // Re-center Button
        view.addSubview(reCenterBtn)
        
        // Open Travel Mode Button
        view.addSubview(travelModeBtn)
        
        // Travel Mode Picker View
        view.addSubview(travelModePickerView)
        travelModePickerView.addSubview(walkingBtn)
        travelModePickerView.addSubview(drivingingBtn)
        travelModePickerView.addSubview(bikingBtn)
        travelModePickerView.addSubview(transitBtn)
        travelModePickerView.addSubview(confirmBtn)
        hideView(view: travelModePickerView) // keep it hidden until travel select button is clicked
    }
}



// ==================================================== //
// =================== CLLocation ===================== //
// ==================================================== //
extension ViewController: CLLocationManagerDelegate {
    
    // ---------------------- Core Location Manager Delegate ---------------------- //
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("[FORGROUND] Lat: \(location.coordinate.latitude) \nLng: \(location.coordinate.longitude)")
            currentLat = location.coordinate.latitude
            currentLng = location.coordinate.longitude
            if !reCenteredInitMap {
                recenterMapToCurrentLocation(lat: currentLat!, lng: currentLng!)
                startInCoordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                self.reCenteredInitMap = true
            }
            publishMsg()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            // Location updates are not authorized.
            print("Error in location service.")
            manager.stopUpdatingLocation()
            // Show an alert to grant permission to use location service
            let alert = UIAlertController(title: "Settings", message: "Allow location from settings", preferredStyle: UIAlertController.Style.alert)
            self.present(alert, animated: true, completion: nil)
            alert.addAction(UIAlertAction(title: "Location Service Required", style: .default, handler: { action in
                switch action.style{
                    case .default:
                        UIApplication.shared.open(NSURL(string: UIApplication.openSettingsURLString)! as URL)
                    case .cancel:
                        print("cancel")
                    case .destructive:
                        print("destructive")
                    @unknown default:
                        print("Unknown Default....")
                }
            }))
            return
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .authorizedAlways:
                print("Authorized Always")
            case .authorizedWhenInUse:
                print("Authorized When in Use")
            case .denied:
                print("Denied")
            case .notDetermined:
                print("Not Determined")
            case .restricted:
                print("Restricted")
            default:
                print("Default. Unexpected Case..")
        }
    }

    
}



// ==================================================== //
// ======================= Map  ======================= //
// ==================================================== //
extension ViewController: GMSMapViewDelegate {
    
    // ---------------------- Google Maps View Delegate ---------------------- //
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
//        let coordinateOnPin = mapView.projection.coordinate(for: mapView.center)
//        print("[Dragged]: Pin Coordinate >> lat: \(coordinateOnPin.latitude), lng: \(coordinateOnPin.longitude)")
        if usePinForCoordinateSelection {
            let coordinateOnPin = mapView.projection.coordinate(for: mapView.center)
            destinationInCoordinate = CLLocationCoordinate2D(latitude: coordinateOnPin.latitude, longitude: coordinateOnPin.longitude)
        } else {
            print("not updating")
        }
    }
    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if (gesture) {
            mapView.selectedMarker = nil
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        self.mapView.isMyLocationEnabled = true
        return false
    }
    
    // Using for pin to set destination
    func mapView(_ mapView: GMSMapView, didBeginDragging marker: GMSMarker) {
        print("Start dragging")
    }
    
    func mapView(_ mapView: GMSMapView, didEndDragging marker: GMSMarker) {
        print("Stop dragging")
        if usePinForCoordinateSelection {
            let coordinateOnPin = mapView.projection.coordinate(for: mapView.center)
            destinationInCoordinate = CLLocationCoordinate2D(latitude: coordinateOnPin.latitude, longitude: coordinateOnPin.longitude)
        } else {
            print("not updating")
        }
    }
    
    func recenterMapToCurrentLocation(lat: CLLocationDegrees, lng: CLLocationDegrees) {
        let move = GMSCameraPosition.camera(withLatitude: lat, longitude: lng, zoom: 12)
        mapView.camera = move
        mapView.animate(toLocation: CLLocationCoordinate2D(latitude: lat, longitude: lng))
    }
    
    @objc func recenterMap() {
        if currentLat != nil && currentLng != nil {
            let move = GMSCameraPosition.camera(withLatitude: self.currentLat!, longitude: self.currentLng!, zoom: 12)
            mapView.camera = move
            mapView.animate(toLocation: CLLocationCoordinate2D(latitude: self.currentLat!, longitude: self.currentLng!))
        } else {
            print("Couldn't fetch your current location.")
        }
    }
    
}

// ==================================================== //
// ======================= MQTT ======================= //
// ==================================================== //
extension ViewController: MQTTSessionDelegate {
        
    func mqttConfig(host: String, port: UInt16, clientId: String) {
        mqttSession = MQTTSession(
            host: host,
            port: port,
            clientID: clientId,
            cleanSession: true,
            keepAlive: 15,
            useSSL: false
        )
        print("Trying to connect to \(host) on port \(port) for clientID \(clientId)")
    }
    
    
    func establishConnection() {

        mqttSession.connect { (error) in
            if error == .none {
                print("Connected.")
                self.publishMsg()
            } else {
                print("Error occurred during connection:")
                print(error.description)
            }
        }
    }
    
    
    func publishMsg() {
        
        let json = ["key" : "hey lo :)"]
        let data = try! JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let topic = "test/matta/318c2f44-5d97-449e-8aef-416757103f10"

        mqttSession.publish(data, in: topic, delivering: .atLeastOnce, retain: false) { error in
            if error == .none {
                print("Published data in \(topic)!")
            } else {
                print(error.description)
            }
        }
    }
    
    // ---------------------- MQTT Session Delegate ---------------------- //
    func mqttDidReceive(message: MQTTMessage, from session: MQTTSession) {
        print("Receive >> \(message)")
    }
    
    func mqttDidAcknowledgePing(from session: MQTTSession) {
        print("Keep-alive ping acknowledged.")
    }
    
    func mqttDidDisconnect(session: MQTTSession, error: MQTTSessionError) {
        print("mqttDidDisConnect")
        if error != .none {
            print("Error: \(error.description)")
        }
    }
    
}


// ==================================================== //
// ====== Autocomplete UI (Google Place Search) ======= //
// ==================================================== //
extension ViewController: GMSAutocompleteViewControllerDelegate {
    
    // Present the Autocomplete view controller when the button is pressed.
    @objc func autocompleteClicked(_ sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self

        // Specify the place data types to return.
        let fields: GMSPlaceField = GMSPlaceField(rawValue:UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.placeID.rawValue) | UInt(GMSPlaceField.coordinate.rawValue) | GMSPlaceField.addressComponents.rawValue | GMSPlaceField.formattedAddress.rawValue )
        autocompleteController.placeFields = fields

        // Specify a filter.
        let filter = GMSAutocompleteFilter()
        filter.type = .address
        autocompleteController.autocompleteFilter = filter

        // Display the autocomplete view controller.
        present(autocompleteController, animated: true, completion: nil)
    }
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        print("Place name: \(String(describing: place.name))")
        setDestinationBtn.setTitle(place.name, for: .normal)
        destinationInName = place.name
        destinationInCoordinate = CLLocationCoordinate2D(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        print("2D co-ordinates >> lat: \(place.coordinate.latitude), lng: \(place.coordinate.longitude)")
        drawPathNative(startLocation: startInCoordinate!, endLocation: destinationInCoordinate!, travelMode: selectedTravelMode)
        self.enableBtn(btn: self.shareBtn) // When destination is set, and route is generated successfully, enable `share` button
        dismiss(animated: true, completion: nil)
    }

    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }

    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }

    
    func drawPathNative(startLocation: CLLocationCoordinate2D, endLocation: CLLocationCoordinate2D, travelMode: String){
        
        let origin = "\(startLocation.latitude),\(startLocation.longitude)"
        let destination = "\(endLocation.latitude),\(endLocation.longitude)"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=\(travelMode)&key=\(apiKey)"
        guard let callUrl = URL(string: url) else { return }
        
        // API response
        URLSession.shared.dataTask(with: callUrl) { (data, response, error) in
            guard let data = data else{return}
            do{
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
//                print("JSON >> \(String(describing: json))")
                
                let routes = json!["routes"] as! [[String: Any]]
                
//                // Set the destination address to `Search Destination` label
//                let legs = routes[0]["legs"] as! [[String: Any]]
//                let endAddress = legs[0]["end_address"] as! String
                
                // print route using Polyline
                for route in routes {
                    let routeOverviewPolyline = route["overview_polyline"] as! Dictionary<String, Any>
                    let points = routeOverviewPolyline["points"] as! String
                    let path = GMSPath.init(fromEncodedPath: points)
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeWidth = 4
                    polyline.strokeColor = UIColor.black
                    polyline.map = self.mapView
                    
                    // Re-center / re-zoom the mapview based on the route.
                    DispatchQueue.main.async {
                        if self.mapView != nil {
                            let bounds = GMSCoordinateBounds(path: path!)
                            self.mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 50.0))
                        }
                    }
                }
            }catch {
                print("Err: \(error)")
            }
            }.resume()
        
    }
    
    // When pin option is selected, start saving the destination coordinate from the center of the screen.
    @objc func pinOptionSelected() {
        self.usePinForCoordinateSelection = true
        hideBtn(btn: setDestinationWithPinBtn)
        showBtn(btn: confirmPinLocationBtn)
    }
    
    // When pin location is confirmed, stop updating the destination.
    @objc func pinCoordinateConfirmed() {
        self.usePinForCoordinateSelection = false
        drawPathNative(startLocation: startInCoordinate!, endLocation: destinationInCoordinate!, travelMode: selectedTravelMode)
        showBtn(btn: setDestinationWithPinBtn)
        enableBtn(btn: setDestinationWithPinBtn)
        hideBtn(btn: confirmPinLocationBtn)
        enableBtn(btn: shareBtn)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

// ==================================================== //
// ==================== Message UI ==================== //
// ==================================================== //
extension ViewController: MFMessageComposeViewControllerDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        // Dismiss the message compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
    
    
}

// ==================================================== //
// =============== General View Methods =============== //
// ==================================================== //
extension ViewController {
    
    // ---------------------- Show/Hide, Enable/Disable  ---------------------- //
    func enableBtn(btn: UIButton) {
        btn.isEnabled = true
        btn.alpha = 1
    }
    
    func disableBtn(btn: UIButton) {
        btn.isEnabled = false
        btn.alpha = 0.5
    }
    
    func showBtn(btn: UIButton) {
        btn.isHidden = false
    }
    
    func hideBtn(btn: UIButton) {
        btn.isHidden = true
    }
    
    func showView(view: UIView) {
        view.isHidden = false
    }
    
    func hideView(view: UIView) {
        view.isHidden = true
    }
    
    func changeBtnColor(btn: UIButton) {
        btn.backgroundColor = .white
        btn.setTitleColor(.red, for: .normal)
    }
    
    func resetBtnColor(btn: UIButton) {
        btn.backgroundColor = .systemIndigo
        btn.setTitleColor(.white, for: .normal)
    }
    
    @objc func setToWalkingMode() {
        travelModeBtn.setTitle("Walking", for: .normal)
        selectedTravelMode = "walking"
        changeBtnColor(btn: walkingBtn) // highlight the selected button
        resetBtnColor(btn: drivingingBtn)
        resetBtnColor(btn: transitBtn)
        resetBtnColor(btn: bikingBtn)
        travelModePicked = true
    }
    
    @objc func setToDrivingMode() {
        travelModeBtn.setTitle("Driving", for: .normal)
        selectedTravelMode = "driving"
        changeBtnColor(btn: drivingingBtn) // highlight the selected button
        resetBtnColor(btn: walkingBtn)
        resetBtnColor(btn: transitBtn)
        resetBtnColor(btn: bikingBtn)
        travelModePicked = true
    }
    
    @objc func setToTransitMode() {
        travelModeBtn.setTitle("Transit", for: .normal)
        selectedTravelMode = "transit"
        changeBtnColor(btn: transitBtn) // highlight the selected button
        resetBtnColor(btn: walkingBtn)
        resetBtnColor(btn: drivingingBtn)
        resetBtnColor(btn: bikingBtn)
        travelModePicked = true
    }
    
    @objc func setToBikingMode() {
        travelModeBtn.setTitle("Biking", for: .normal)
        selectedTravelMode = "biking"
        changeBtnColor(btn: bikingBtn) // highlight the selected button
        resetBtnColor(btn: walkingBtn)
        resetBtnColor(btn: transitBtn)
        resetBtnColor(btn: drivingingBtn)
        travelModePicked = true
    }
    
    @objc func confirmBtnClicked() {
        if travelModePicked {
            hideView(view: travelModePickerView)
            resetBtnColor(btn: walkingBtn)
            resetBtnColor(btn: drivingingBtn)
            resetBtnColor(btn: bikingBtn)
            resetBtnColor(btn: transitBtn)
            enableBtn(btn: setDestinationBtn)
            enableBtn(btn: setDestinationWithPinBtn)
        } else {
            resetBtnColor(btn: walkingBtn)
            resetBtnColor(btn: drivingingBtn)
            resetBtnColor(btn: bikingBtn)
            resetBtnColor(btn: transitBtn)
            hideView(view: travelModePickerView)
        }
    }
    
    @objc func travelModeBtnClicked() {
        showView(view: travelModePickerView)
    }
    
    @objc func setTravelModeBtnClicked() {
        showView(view: travelModePickerView)
    }
    
    // Open Message View
    @objc func displayMessageInterface() {
        let composeVC = MFMessageComposeViewController()
        composeVC.messageComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.recipients = ["5714391600"]
        composeVC.body = "Message from Matta! Che is on his way. He is using \(travelModePicked) mode to arrive to the destination."
        
        // Present the view controller modally.
        if MFMessageComposeViewController.canSendText() {
            self.present(composeVC, animated: true, completion: nil)
        } else {
            print("Can't send messages.")
        }
    }
}
