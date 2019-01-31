//
//  UserInfoViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import MapKit

class UserInfoViewController: UIViewController {

    @IBOutlet var codeLabel: UILabel!
    @IBOutlet var tokenLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!

    @IBOutlet var mapView: MKMapView!

    @IBOutlet var activity: UIActivityIndicatorView!

    @IBOutlet var debugButton: UIButton!

    var authzCode: String?

    var token: String?
    var userInfo: String?

    /// Do any additional setup after loading the view.
    override func viewDidLoad() {
        super.viewDidLoad()

        debugButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)

        if let code = authzCode {
            codeLabel.text = "AuthZ: \(code)"
            login(with: code)
        } else {
            let json = JsonDocument(string: "{\"phone\":\"4079395277\",\"name\":\"Mickey Mouse\",\"email\":\"mickey@disney.com\",\"address\":\"1180 Seven Seas Dr, Lake Buena Vista, FL 32830\"}")

            displayUserInfo(from: json)
        }
    }

    @IBAction func debug() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DebugViewController") as! DebugViewController
        vc.finalInit(with: DebugViewController.Info(token: token, userInfo: userInfo))
        present(vc, animated: true, completion: nil)
    }

    var geocoder: CLGeocoder?

    func displayUserInfo(from json: JsonDocument) {
        if let name = json["name"].toString {
            nameLabel.text = name
        }
        if let email = json["email"].toString {
            emailLabel.text = email
        }
        if let address = json["address"].toString {
            addressLabel.text = address

            let geocoder = CLGeocoder()
            self.geocoder = geocoder
            let mapView = self.mapView!
            geocoder.geocodeAddressString(address) { (placemarks, error) in
                if let topResult = placemarks?.first {
                    let placemark = MKPlacemark(placemark: topResult)
                    mapView.addAnnotation(placemark)
                    mapView.setCenter(placemark.coordinate, animated: true)

                    if let region = placemark.region as? CLCircularRegion {
                        let mkRegion = MKCoordinateRegionMakeWithDistance(region.center, region.radius*4, region.radius*2)
                        mapView.setRegion(mkRegion, animated: true)
                    }
                }
            }
        }
        if let phone = json["phone"].toString {
            phoneLabel.text = phone
        }
    }

    let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: Foundation.OperationQueue.main)
    var dataTask: URLSessionDataTask?

    /// Log in.
    ///
    /// - Parameter code: The code to log in with.
    func login(with code: String) {

        // call /token

        var request = URLRequest(url: URL(string: "https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let authorizationCode = "\(AppConfig.clientID):\(AppConfig.clientSecret)".data(using: .utf8)?.base64EncodedString() ?? ""
        request.setValue("BASIC \(authorizationCode)", forHTTPHeaderField: "Authorization")
        request.httpBody = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": AppConfig.clientID,
            "client_secret": AppConfig.clientSecret,
            "redirect_uri": AppConfig.code_redirect_uri
            ].encodeAsUrlParams().data(using: .utf8)

        //        print("url: \(request)")

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                //                print("data: \(NSData(data: data))")
                let json = JsonDocument(data: data)

                if let accessToken = json["access_token"].toString {
                    self.tokenLabel.text = "Token: \(accessToken)"
                    self.token = json.description

                    self.getUserInfo(with: accessToken)
                }
            }
            //            print("response: \(response)")
            //            print("error: \(error)")
            //            print("foo")
        }
        self.dataTask = dataTask
        dataTask.resume()
    }

    func getUserInfo(with accessToken: String) {
        var request = URLRequest(url: URL(string: "https://oidc.test.xlogin.att.com/mga/sps/oauth/oauth20/userinfo")!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        //        print("url: \(request)")

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let data = data {
                //                print("data: \(NSData(data: data))")
                let json = JsonDocument(data: data)

                self.userInfo = json.description

                self.activity.stopAnimating()

                self.displayUserInfo(from: json)
            }
            //            print("response: \(response)")
            //            print("error: \(error)")
            //            print("foo")
        }
        self.dataTask = dataTask
        dataTask.resume()
    }

    @IBAction func logout() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.logout()
        }
    }
}
