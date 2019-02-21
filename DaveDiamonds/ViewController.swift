//
//  ViewController.swift
//  DaveDiamonds
//
//  Created by Chaudhry Talha on 2/15/19.
//  Copyright © 2019 ibjects. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import PopupDialog

class ViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    //MARK: - UI objects Outlets
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var gameScoreView: UIView!
    @IBOutlet weak var diamondScoreView: UIView!
    @IBOutlet weak var butterflyScoreView: UIView!
    @IBOutlet weak var featherScoreView: UIView!
    
    @IBOutlet weak var diamondScoreLabel: UILabel!
    @IBOutlet weak var butterflyScoreLabel: UILabel!
    @IBOutlet weak var featherScoreLabel: UILabel!
    
    //MARK: - Location variables
    var locationManager = CLLocationManager() //Help in setting up user location
    var userLocation = CLLocation() //Keep track of user location
    //MARK: - Map camera variables
    var bearingAngle = 270.0 //Bearing is the orientation of the camera. Bearing is the direction in which determines where the map camera will face.
    var angleOfView = 65.0 //In google maps 65 is the maximum value and also this is the angle that will give it a bit of 3D look.
    var zoomLevel:Float = 18 //This is about right level of zoom as per the size of character we are using.
    var capitolLat = 38.889815 //Default location if the map if user location is not available will be US capital.
    var capitolLon = -77.005900 //Default location if the map if user location is not available will be US capital.
    //MARK: - Custom user marker variables
    var userMarker = GMSMarker() //Marker to represent user location
    let userMarkerimageView = UIImageView(image: UIImage.gifImageWithName("player")) //Initializing the Image view of player marker gif icon
    //MARK: - Scoring Variables
    var diamond1Score = 00
    
    //MARK: - Main Function
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpScoreView()
        initializeMap()
        addMarkers()
    }
    
    //MARK: - Map settings
    func setMapTheme(theme: String) {
        if theme == "Day" {
            do {
                if let styleURL = Bundle.main.url(forResource: "DayStyle", withExtension: "json") {
                    mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                } else {
                    NSLog("Unable to find DayStyle.json")
                }
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
        } else if theme == "Evening" {
            do {
                if let styleURL = Bundle.main.url(forResource: "EveningStyle", withExtension: "json") {
                    mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                } else {
                    NSLog("Unable to find EveningStyle.json")
                }
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
        } else {
            do {
                if let styleURL = Bundle.main.url(forResource: "NightStyle", withExtension: "json") {
                    mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                } else {
                    NSLog("Unable to find NightStyle.json")
                }
            } catch {
                NSLog("One or more of the map styles failed to load. \(error)")
            }
        }
    }
    
    func centerMapAtUserLocation() {
        
        //get user current location coordinates
        let locationObj = locationManager.location
        let coord = locationObj?.coordinate
        let lattitude = coord?.latitude
        let longitude = coord?.longitude
        
        //Uncomment isMyLocationEnabled to hide blue marker underneath the player
        //mapView.isMyLocationEnabled = true
        userMarkerimageView.frame = CGRect(x: 0, y: 0, width: 40, height: 70)
        
        //center camera on those coordinates
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: lattitude ?? capitolLat, longitude: longitude ?? capitolLon, zoom: zoomLevel, bearing: bearingAngle, viewingAngle: angleOfView)
        self.mapView.animate(to: camera)
        
    }
    
    func checkUserPermission() {
        
        locationManager.delegate = self
        
        if CLLocationManager.locationServicesEnabled() {
            switch (CLLocationManager.authorizationStatus()) {
            case .notDetermined:
                perform(#selector(presentNotDeterminedPopup), with: nil, afterDelay: 0)
            case .restricted, .denied:
                perform(#selector(presentDeniedPopup), with: nil, afterDelay: 0)
            case .authorizedAlways, .authorizedWhenInUse:
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager.startUpdatingLocation()
                locationManager.startUpdatingHeading()
                centerMapAtUserLocation() //step 3
            }
        } else {
            perform(#selector(presentDeniedPopup), with: nil, afterDelay: 0)
        }
    }
    
    @objc private func presentNotDeterminedPopup() {
        
        let title = "Allow Location"
        let message = "Allow location to discover and collect diamonds near you."
        let image = UIImage(named: "userLocation-cover")
        
        let popup = PopupDialog(title: title, message: message, image: image)
        let skipButton = CancelButton(title: "Skip for now") {
            //print("You canceled the car dialog.")
            self.dismiss(animated: true, completion: nil)
        }
        let okButton = DefaultButton(title: "Okay") {
            //self.locationManager.delegate = self
            self.locationManager.requestWhenInUseAuthorization()
        }
        popup.addButtons([skipButton, okButton])
        self.present(popup, animated: true, completion: nil)
    }
    
    @objc private func presentDeniedPopup() {
        
        let title = "Allow Location"
        let message = "Allow location to discover and collect diamonds near you. Open setting and allow location when in use."
        let image = UIImage(named: "userLocation-cover")
        
        let popup = PopupDialog(title: title, message: message, image: image)
        let skipButton = CancelButton(title: "Skip for now") {
            print("You canceled the car dialog.")
        }
        let settingsButton = DefaultButton(title: "Open Settings", dismissOnTap: false) {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
            
        }
        popup.addButtons([skipButton, settingsButton])
        self.present(popup, animated: true, completion: nil)
    }
    
    //MARK: - Location permission Delegate Method
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            perform(#selector(presentNotDeterminedPopup), with: nil, afterDelay: 0)
        case .restricted, .denied:
            perform(#selector(presentDeniedPopup), with: nil, afterDelay: 0)
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
            self.centerMapAtUserLocation() //step 3
        }
    }
    
    //MARK: - All methods related to map combined
    func initializeMap() {
        
        self.mapView.delegate = self
        
        let camera = GMSCameraPosition.camera(withLatitude: capitolLat, longitude: capitolLon, zoom: zoomLevel, bearing: bearingAngle,
                                              viewingAngle: angleOfView)
        self.mapView.camera = camera
        
        //set map mode
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 7..<15 : setMapTheme(theme: "Day")
        case 15..<18 : setMapTheme(theme: "Evening")
        default: setMapTheme(theme: "Night")
        }
        
        //Interaction with map
        self.mapView.settings.tiltGestures = false
        self.mapView.settings.rotateGestures = false
        self.mapView.settings.zoomGestures = false
        self.mapView.settings.compassButton = true
        mapView.settings.allowScrollGesturesDuringRotateOrZoom = true
        mapView.settings.indoorPicker = false
        //mapView.isBuildingsEnabled = false
        self.mapView.settings.scrollGestures = false
        
        //CenterMap with user location
        checkUserPermission() //step 2
    }
    
    //MARK: - Map Delegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last ?? CLLocation(latitude: capitolLat, longitude: capitolLon)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, zoom: zoomLevel, bearing: bearingAngle, viewingAngle: angleOfView)
        self.mapView.animate(to: camera)
        mapView.animate(toBearing: newHeading.magneticHeading)
        //delete the old user location marker first
        userMarker.map = nil
        userMarker.position = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        userMarker.iconView = userMarkerimageView
        userMarker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
        userMarker.map = mapView
    }
    
    //MARK: - Map Markers Methods
    
    func distanceInMeters(marker: GMSMarker) -> CLLocationDistance {
        
        let markerLocation = CLLocation(latitude: marker.position.latitude , longitude: marker.position.longitude)
        let metres = locationManager.location?.distance(from: markerLocation)
        return Double(metres ?? -1) //will be in metres
    }
    
    func addMarkers() {
        
        let diamond1Gif = UIImage.gifImageWithName("diamond1")
        let diamond1GifView = UIImageView(image: diamond1Gif)
        diamond1GifView.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        
        let randomLatDC = [38.921074,38.87501,38.920387,38.876737,39.120045,39.099376,39.083673,39.123513,38.990249,39.107709,38.982456,39.025387,39.095661,
                           38.989724,38.975,38.977933,38.99237538,38.990639,38.977093,39.102099,39.094103,39.076331,39.102212,38.992679,
                           38.999388,38.997033,39.114688,39.110314,38.923583,38.90706,38.898536,38.908473,38.878433,38.873755,38.862753,38.999634,
                           38.96115,38.899703,38.837666,38.873219,38.869418,38.941154,39.103091,39.097636,38.997445,38.928121,38.917761,38.889935,38.930282,
                           38.896544,38.905126,38.88732,38.844711,38.876393,38.850337,38.896923,38.9024,38.885801,38.896355,38.878854,38.922649,38.928743,
                           38.882788,38.88397,38.884734,38.888553,38.888767,38.87887,38.894573,38.893237,38.89593,38.89054,38.88081,38.881044,39.085394,
                           38.900358,38.952369,38.975219,38.920682,38.866471,38.839912,39.119765,38.964992,39.084379,38.984691,38.88992,38.903663,
                           38.804378,38.894941,38.869442,38.898243,38.897612,38.901755,38.801111,38.82175,38.802677,38.820064,38.82595,38.820932]
        
         let randomLonDC = [-77.031887,-77.0024,-77.025672,-76.994468,-77.156985,-77.188014,-77.149162,-77.15741,-77.02935,-77.152072,-77.091991,-77.044563,
                            -77.159048,-77.023854,-77.01121,-77.006472,-77.100104,-77.100239,-77.094589,-77.200322,-77.132954,-77.141378,-77.177091,
                            -77.029457,-77.031555,-77.025608,-77.171487,-77.182669,-77.050046,-77.015231,-76.931862,-76.933099,-77.03023,-77.089233,
                            -77.05428,-77.109647,-77.088659,-77.008911,-77.09482,-77.082104,-77.095596,-77.062036,-77.196442,-77.196636,-77.023894,
                            -77.023795,-77.04062,-76.93723,-77.055599,-76.96012,-77.056887,-76.983569,-76.987823,-77.107735,-77.100989,-77.086502,
                            -77.02622,-77.097745,-77.078408,-77.005727,-77.077271,-77.012457,-77.103148,-77.10783,-77.093485,-77.032429,-77.02858,
                            -77.1207,-77.01994,-77.086063,-77.089006,-77.08095,-77.090792,-77.111768,-77.145803,-77.012108,-77.002721,-77.016855,
                            -76.995876,-77.076131,-77.087083,-77.166093,-77.103381,-77.146866,-77.094537,-77.071301,-77.067668,-77.060866,
                            -77.09169,-77.104503,-77.026235,-77.080851,-77.051084,-77.068952,-77.047494,-77.063562,-77.057619,-77.058541,-77.053096]
        
        
        for i in 0..<randomLonDC.count {
            var marker:  GMSMarker?
            let position = CLLocationCoordinate2D(latitude: randomLatDC[i], longitude: randomLonDC[i])
            marker = GMSMarker(position: position)
            marker?.title = "Distance Left: \(round(100*distanceInMeters(marker: marker!)*0.00062137)/100) miles" //converting meters to miles
            marker?.map = mapView
            marker?.iconView = diamond1GifView
        }
    }
    
    //MARK: - Map Markers Delegate method
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        let distanceinMiles = round(100*distanceInMeters(marker: marker)*0.00062137)/100
        print(distanceinMiles)
        if distanceinMiles < 0.2 {
            let title = "Added to collection"
            let message = "Marker added to your collection"
            
            let popup = PopupDialog(title: title, message: message)
            let okButton = DefaultButton(title: "Yayyy!") {
                self.diamond1Score = self.diamond1Score + 1
                self.diamondScoreLabel.text = "\(self.diamond1Score)"
                //destory that marker
                marker.map = nil
            }
            popup.addButton(okButton)
            self.present(popup, animated: true, completion: nil)
        } else {
            let title = "Too Far!"
            let message = "You're too far from this diamond. Get closer!"
            
            let popup = PopupDialog(title: title, message: message)
            let okButton = DefaultButton(title: "Ok") {
                
            }
            popup.addButton(okButton)
            self.present(popup, animated: true, completion: nil)
        }
        
        return true
        
    }
    
    //MARK: - ScoreView
    func setUpScoreView() {
        self.view.bringSubviewToFront(gameScoreView)
        gameScoreView.layer.cornerRadius = 10
        gameScoreView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
        diamondScoreView.layer.cornerRadius = 25
        butterflyScoreView.layer.cornerRadius = 25
        featherScoreView.layer.cornerRadius = 25
        
        diamondScoreView.layer.masksToBounds = true
        butterflyScoreView.layer.masksToBounds = true
        featherScoreView.layer.masksToBounds = true
    }
}

