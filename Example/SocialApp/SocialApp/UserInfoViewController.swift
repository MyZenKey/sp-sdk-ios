//
//  UserInfoViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import MapKit

class UserInfoViewController: UIViewController,MKMapViewDelegate {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!
    @IBOutlet var SearchQueryLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    var selectedPinMapItem: MKMapItem?
    @IBOutlet var activity: UIActivityIndicatorView!
    @IBOutlet var debugButton: UIButton!
    var url: URL?
    var tokenInfo: String?
    var userInfo: String?
    var userInfoJson: JsonDocument?
    var code: String?

    /// Do any additional setup after loading the view.
    override func viewDidLoad() {
        super.viewDidLoad()
        print("UserInfoViewController has loaded")
        debugButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        if let info = self.userInfoJson {
            print("User Info found")
            self.displayUserInfo(from: info)
        }
        else {
            if let url = url {
                if(url.absoluteString != "mock") {
                    let urlComp = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    if let code = urlComp?.queryItems?.filter({ $0.name == "code" }).first?.value {
                        let serviceAPIObject = ServiceAPI()
                        
                        serviceAPIObject.login(with: code, completionHandler: { (result) in
                            if let accessToken = result["access_token"].toString {
                                
                                UserDefaults.standard.set(accessToken,forKey: "AccessToken")
                                UserDefaults.standard.synchronize();
                                
                                self.tokenInfo = result.description
                                serviceAPIObject.getUserInfo(with: accessToken, completionHandler: {(userInfoResponse) in
                                    
                                    UserDefaults.standard.set(result.description,forKey: "UserInfoJSON")
                                    UserDefaults.standard.synchronize();
                                    self.code = "AuthZ: \(code)"
                                    self.userInfo = userInfoResponse.description
                                    self.displayUserInfo(from: userInfoResponse)
                                })
                            }
                        } )
                    }
                }else{
                    let json = JsonDocument(string: "")
                    
                    displayUserInfo(from: json)
                }
            }
        }
    }

    @IBAction func debug() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DebugViewController") as! DebugViewController
        vc.finalInit(with: DebugViewController.Info(token: self.tokenInfo, userInfo: self.userInfo, code: self.code))
        present(vc, animated: true, completion: nil)
    }

    var geocoder: CLGeocoder?
    
    func displayUserInfo(from json: JsonDocument) {
 
        if let phone = json["phone_number"].toString {
            self.phoneLabel.text = phone
        }
        
        if let family_name = json["family_name"].toString, let given_name = json["given_name"].toString {
            self.nameLabel.text = "\(given_name) \(family_name)"
            
        }
        else if let full_name = json["name"].toString {
            self.nameLabel.text = full_name
        }
        
        
        if let email = json["email"].toString {
            self.emailLabel.text = email
        }
        
        if let zip = json["postal_code"].toString {
        
            let zipCode = zip.prefix(5)
            var dummyAddress = ""
            let googleapiURL = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(zipCode)&sensor=false&key=laksjdf;kqwe;lf")
            URLSession.shared.dataTask(with:googleapiURL!, completionHandler: {(data, response, error) in
                guard let data = data, error == nil else {return}
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let blogs = json["results"] as? [[String: Any]] {
                        for iteration in blogs {
                            
                            if let address = (iteration["formatted_address"]) as? String {
                                print("The address extracted from ZIP code is \(address)")
                                dummyAddress = address
                                
                                DispatchQueue.main.async {
                                    self.addressLabel.text = dummyAddress
                                }
                                let geocoder = CLGeocoder()
                                self.geocoder = geocoder
                                let mapView = self.mapView!
                                geocoder.geocodeAddressString(address) { (placemarks, error) in
                                    if let topResult = placemarks?.first {
                                        let placemark = MKPlacemark(placemark: topResult)
                                        mapView.mapType = MKMapType.standard
                                        mapView.setCenter(placemark.coordinate, animated: true)
                                        
                                        let span = MKCoordinateSpanMake(0.05, 0.05)
                                        let mkRegion = MKCoordinateRegionMake(placemark.coordinate, span)
                                        
                                        let request = MKLocalSearchRequest()
                                        request.naturalLanguageQuery = AppConfig.searchQuery
                                        request.region = mkRegion
                                        
                                        self.SearchQueryLabel.text = "\(AppConfig.searchQuery) near \(zipCode)"
                                        
                                        let search = MKLocalSearch(request: request)
                                        
                                        search.start(completionHandler: { (results, error) in
                                            
                                            if let err = error {
                                                print("Error occurred in search: \(err.localizedDescription)")
                                            } else if results?.mapItems.count == 0 {
                                                print("No matches found")
                                            } else {
                                                print("Matches found")
                                                var matchingItems: [MKMapItem] = [MKMapItem]()
                                                for item in (results?.mapItems)!{
                                                    
                                                    print("Name = \(item.name ?? "No match")")
                                                    matchingItems.append(item as MKMapItem)
                                                   
                                                    self.selectedPinMapItem = item
                                        
                                                    let annotation = MKPointAnnotation()
                                                    annotation.coordinate = item.placemark.coordinate
                                                    annotation.title = item.name
                                                    annotation.subtitle = "\(String(describing: placemark.locality!)), \(String(describing: placemark.administrativeArea!))"
                                                    self.mapView.addAnnotation(annotation)
                                                }
                                                print("Matching items = \(matchingItems.count)")
                                                
                                            }
                                        })
                                        
                                        mapView.setRegion(mkRegion, animated: true)
                                        
                                        DispatchQueue.main.async {    
                                             self.activity.stopAnimating()
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch let error as NSError {
                    print("Error deserializing JSON: \(error)")
                }
            }).resume()
            
        }
    }
    
    @objc func getDirections(){
        guard let selectedPin = selectedPinMapItem else { return }
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        selectedPin.openInMaps(launchOptions: launchOptions)
    }

    @IBAction func logout() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.logout()
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{

        let reuseId = "pin"
        var pinView = self.mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
           // pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)

            pinView?.isEnabled = true
            pinView?.canShowCallout = true
            pinView?.image = UIImage(named: "custom_pin.png")

            let detailButton = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = detailButton

            let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 30, height: 30)))
            button.setBackgroundImage(UIImage(named: "car-drive.png"), for: .normal)
            button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
            pinView?.leftCalloutAccessoryView = button



        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
}

