//
//  CheckoutViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import AppAuth
import CarriersSharedAPI

class CheckoutViewController: UIViewController {

    
    var typeOfSegue: String?
    var authzCode: String?
    var tokenInfo: String?
    var userInfo: String?
    let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: Foundation.OperationQueue.main)
    var dataTask: URLSessionDataTask?
    var url: URL?
    @IBOutlet var poweredByContainer: UIView!
    @IBOutlet var poweredByLabel: UILabel!
    @IBOutlet var poweredByTrailing: NSLayoutConstraint!
    @IBOutlet var nameTF: UITextField!
    @IBOutlet var phoneTF: UITextField!
    @IBOutlet var zipTF: UITextField!
    @IBOutlet var addressTF: UITextField!
    @IBOutlet var emailTF: UITextField!
    var window: UIWindow?
    var openidconfiguration: OIDServiceConfiguration?
    var carrier:String?
    var clientId:String? = "PhotoApp"
    var secret:String? = "photoapp_client_secret"
    var state:String? = ""
    var redirectUri:String? = "com.att.ent.cso.haloc.photoapp://code"
    var sharedAPI:SharedAPI?
    var carrierConfig:[String:Any]? = nil
    var scopes:[String]? = nil
    var responseTypes:[String]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //init shared api
        self.sharedAPI = SharedAPI()
        
        //get carrier data
        self.carrierConfig = sharedAPI!.discoverCarrierConfiguration()
        self.scopes = (carrierConfig!["scopes_supported"] as! String).components(separatedBy: " ")
        self.responseTypes = [carrierConfig!["response_types_supported"]! as! String]
        
        if let logo = UIImage(named: "carrier-logo") {
            poweredByTrailing.isActive = false
            let imageView = UIImageView(image: logo)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.required, for: .vertical)
            poweredByLabel.addSubview(imageView)
            
            imageView.leadingAnchor.constraint(equalTo: poweredByLabel.trailingAnchor, constant: 4).isActive = true
            imageView.trailingAnchor.constraint(equalTo: poweredByContainer.trailingAnchor).isActive = true
            imageView.heightAnchor.constraint(equalTo: poweredByLabel.heightAnchor).isActive = true
            imageView.centerYAnchor.constraint(equalTo: poweredByLabel.centerYAnchor).isActive = true
        } else {
            //poweredByLabel.text = "Powered by \(carrier.name)"
        }
        
        print("Checking for non-null url passed from app delegate")
        if let url = url {
            print("Found url")
            let urlComp = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let code = urlComp?.queryItems?.filter({ $0.name == "code" }).first?.value {
                print("Found code - " + code)
                self.authzCode = code
                self.login(with: code)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onUseVerifyKeyAddressTapped(_ sender: Any) {
        
        //check if carrier config is nil
        if self.carrierConfig != nil {
            print("Found value carrier configuration. Setting auth and token urls in openid config")
            //init service configuration object
            let authorizationUrlString:String? = self.carrierConfig!["authorization_endpoint"] as! String
            let tokenUrlString:String? = self.carrierConfig!["token_endpoint"] as! String
            let authorizationURL:URL = URL(string: authorizationUrlString!)!
            let tokenURL:URL = URL(string: tokenUrlString!)! as! URL
            self.openidconfiguration = OIDServiceConfiguration.init(authorizationEndpoint: authorizationURL, tokenEndpoint: tokenURL)
            
            //create the authorization request
            let authorizationRequest:OIDAuthorizationRequest = self.createAuthorizationRequest(scopes: self.scopes!, responseType: self.responseTypes!)!
            print("Authorization Request created")
            
            //check to see if the authorization url is set as a universal app link
            UIApplication.shared.open(authorizationURL, options: [UIApplicationOpenURLOptionUniversalLinksOnly: true], completionHandler: { success in
                if success {
                    print("This url can be opened in an app. Launching app...")
                    self.initProjectVerifyAuthorization(request: authorizationRequest)
                }
                else {
                    print("Launching default safari controller process...")
                    self.performAuthorization(request: authorizationRequest)
                }
            })
        }
        else {
            print("Carrier Config is null. Cannot perform authentication")
        }
        
        /*let consentUrlString = "\(AppConfig.AuthorizeURL)?client_id=\(AppConfig.clientID.urlEncode())&response_type=code&state=teststate&redirect_uri=\(AppConfig.code_redirect_uri.urlEncode())&scope=\(AppConfig.consentScope.urlEncode())"*/
        
     /*   // URL scheme: com.att.ent.cso.haloc.consent
        let destinationUrl = consentUrlString.data(using: String.Encoding.utf8)?.base64EncodedString() ?? ""
        if let url = URL(string: "com.att.ent.cso.haloc.consent://\(destinationUrl)") {
            
            // TODO: Figure out why canOpenURL() is false?
            
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    NSLog("Successful!")
                }
            }
            
            return
        }*/
        
        /*let url = URL(string: consentUrlString)!
        
        UIApplication.shared.open(url, options: [UIApplicationOpenURLOptionUniversalLinksOnly: true]) { [weak self] success in
            
            let storyboard = UIStoryboard(name:"Main", bundle: nil)
            let loginVC = storyboard.instantiateInitialViewController()
            UIApplication.shared.keyWindow?.rootViewController = loginVC
            
            if success {
                NSLog("Successful!")
            } else {
//                UIApplication.shared.open(url, options: [:]) { success in
//                    NSLog("Successful for non-Universal Link? \(success)")
//                }
                self?.showOkAlert(title: "Sorry, looks like something went wrong. Please try again.", message: nil)
            }
        }*/
    }
    
    //this function will initialize the authorization request
    func createAuthorizationRequest(scopes: [String], responseType: [String]) -> OIDAuthorizationRequest? {
        
        //init the authorization redirect
        let redirectUrl:URL? = URL(string: self.redirectUri!) as! URL
        
        //init extra params
        let extraParams:[String:String] = [String:String]()
        
        //compile request
        do {
            let request:OIDAuthorizationRequest = OIDAuthorizationRequest.init(configuration: self.openidconfiguration!, clientId: self.clientId!, clientSecret: self.secret, scope: "openid email profile", redirectURL: redirectUrl, responseType: responseType[0], state: "", nonce: nil, codeVerifier: nil, codeChallenge: nil, codeChallengeMethod: nil, additionalParameters: nil)
            /*let request:OIDAuthorizationRequest =  OIDAuthorizationRequest(configuration: self.openidconfiguration!, clientId: self.clientId!, scopes: self.scopes, redirectURL: redirectUrl!, responseType: responseType[0], additionalParameters: extraParams as! [String : String])*/
            request.setValue(sharedAPI!.carrierName, forKeyPath: "state")
            return request
        }
        catch let error {
            print("Error occurred - \(error)")
        }
        return nil
    }
    
    //this function will initialize the authorization request via Project Verify
    func initProjectVerifyAuthorization(request: OIDAuthorizationRequest) {
        //init app delegate and set the authorization flow
        var url:String = self.carrierConfig!["authorization_endpoint"] as! String
        var scopes = self.carrierConfig!["scopes_supported"] as! String
        let consentUrlString = "\(url)?client_id=\(clientId!.urlEncode())&response_type=code&redirect_uri=\(redirectUri!.urlEncode())&scope=\(scopes.urlEncode())"
        print("Checking if " + consentUrlString + " is part of a universal link")
        var optionalUrl:Optional<URL> = URL(string:consentUrlString)
        var urlTransformation = OIDExternalUserAgentIOSCustomBrowser.urlTransformationSchemeConcatPrefix(consentUrlString)
        let externalUserAgent:OIDExternalUserAgentIOSCustomBrowser = OIDExternalUserAgentIOSCustomBrowser.init(urlTransformation: urlTransformation, canOpenURLScheme: nil, appStore: URL(string: consentUrlString))!
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, externalUserAgent:externalUserAgent, callback: { (authState, error) in
            print("authorization handed off to application")
        })
    }
    
    //this function will init the authstate object
    func performAuthorization(request: OIDAuthorizationRequest) {
        print("Making Authorization Request")
        
        //init app delegate and set the authorization flow
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: self, callback: { (authState, error) in
            print("Authorization callback has completed")
            
            if(error == nil) {
                print("Authentication passed. Redirecting to UserInfoViewController")
                let authorizationCode = authState!.lastAuthorizationResponse.authorizationCode
                var accessToken = authState?.lastTokenResponse?.accessToken
                print("Authentication passed. Extracting access token - " + accessToken!)
                
                /*//init view controller for user info
                 let url = self.redirectUri! + "?code=" + authorizationCode!
                 let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserInfoViewController") as! UserInfoViewController
                 vc.url = URL(string: url)
                 self.navigationController?.viewControllers.removeAll()
                 self.navigationController?.viewControllers.append(vc)
                 print("view controller loaded")*/
                
                //perform a simple GET request to gather the user information
                let userInfoUrl = URL(string: self.carrierConfig!["userinfo_endpoint"] as! String)
                let request = NSMutableURLRequest(url: userInfoUrl! as URL)
                request.httpMethod = "GET"
                request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
                let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
                    print("User information response has returned - ")
                    if(error == nil) {
                        if let res = response as? HTTPURLResponse {
                            print(res)
                            let responseString = String(data: data!, encoding:String.Encoding.utf8) as String!
                            print(responseString)
                        
                            //convert the json string to pure json
                            if let json = responseString!.data(using: String.Encoding.utf8){
                                var jsonDocument:JsonDocument = JsonDocument(data: json)
                                //perform async task to update UI
                                DispatchQueue.main.async {
                                    //update the user information fields
                                    if let name = jsonDocument["name"].toString {
                                        self.nameTF.text = name
                                    }
                                    if let email = jsonDocument["email"].toString {
                                        self.emailTF.text = email
                                    }
                                }
                            }
                        }
                    }
                    else {
                        print(error)
                    }
                }
                task.resume()
            }
            else {
                print("Authorization failed - " + error.debugDescription)
            }
        })
    }
    
    @IBAction func debug() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DebugViewController") as! DebugViewController
        vc.finalInit(with: DebugViewController.Info(token: tokenInfo, userInfo: userInfo, code: authzCode))
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func cancel() {

        if self.typeOfSegue == "push" {
              self.navigationController?.popViewController(animated: true)
        } else {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NavViewController")
            present(vc, animated: true, completion: nil)
        }
}
    
    func login(with code: String) {
        
        var request = URLRequest(url: URL(string: self.carrierConfig!["token_endpoint"] as! String)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let authorizationCode = "\(self.clientId):\(self.secret)".data(using: .utf8)?.base64EncodedString() ?? ""
        request.setValue("BASIC \(authorizationCode)", forHTTPHeaderField: "Authorization")
        //request.httpBody = [].encodeAsUrlParams().data(using: .utf8)
        
        print("url: \(request)")
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {return}
            if let data = data {
                let json = JsonDocument(data: data)
                self.tokenInfo = json.description
                if let accessToken = json["access_token"].toString {
                    print(accessToken)
                    UserDefaults.standard.set(accessToken,forKey: "AccessToken")
                    UserDefaults.standard.synchronize();
                    self.getUserInfo(with: accessToken)
                }
            }
            
        }
        self.dataTask = dataTask
        dataTask.resume()
    }
    
    func getUserInfo(with accessToken: String) {
        var request = URLRequest(url: URL(string: self.carrierConfig!["userinfo_endpoint"] as! String)!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        DispatchQueue.main.async {
            
            let dataTask = self.session.dataTask(with: request) { (data, response, error) in
                guard error == nil else {return}
                if let data = data {
        
                    let json = JsonDocument(data: data)
                    
                    print(json.description)
                    UserDefaults.standard.set(json.description,forKey: "UserInfoJSON")
                    UserDefaults.standard.synchronize();
                    
                    self.displayUserInfo(from: json)
                }
            }
            self.dataTask = dataTask
            dataTask.resume()
        }
    }
    
    
    func displayUserInfo(from json: JsonDocument){
        print("Populating user information..")
        self.userInfo = json.description
       
        if let family_name = json["family_name"].toString, let given_name = json["given_name"].toString {
            self.nameTF.text = "\(given_name) \(family_name)"
        }
        if let email = json["email"].toString {
            emailTF.text = "john@email.com"
        }
         if let phone = json["phone_number"].toString {
            phoneTF.text = phone
        }
        if let zip = json["postal_code"].toString {
            zipTF.text = String(zip.prefix(5))
            var dummyAddress = ""
            let googleapiURL = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?address=\(zip.prefix(5))&sensor=false&key=laksdfjkjahsdfjhqfjw")
            URLSession.shared.dataTask(with:googleapiURL!, completionHandler: {(data, response, error) in
                guard let data = data, error == nil else {return}
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                        let blogs = json["results"] as? [[String: Any]] {
                        for iteration in blogs {
                            
                            if let address = (iteration["formatted_address"]) as? String {
                                print("The address extracted from ZIP code is \(address)")
                                dummyAddress = address.replacingOccurrences(of: " \(zip.prefix(5))", with: "")
                                
                                DispatchQueue.main.async {
                                    self.addressTF.text = dummyAddress
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
    
}
