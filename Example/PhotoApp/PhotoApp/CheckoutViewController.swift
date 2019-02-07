//
//  CheckoutViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import AppAuth
import CarriersSharedAPI

class CheckoutViewController: UIViewController {
    
    let nameField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Name"
        return field
    }()
    
    let emailField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Email"
        return field
    }()
    
    let phoneField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Phone"
        return field
    }()
    
    let cityField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "City, State"
        return field
    }()
    
    let zipField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Phone"
        return field
    }()
    
    let requiredLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "*All fields are required"
        label.font = UIFont.italicSystemFont(ofSize: 12)
        label.textColor = .red
        return label
    }()
    
    let checkoutButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = AppTheme.themeColor
        button.setTitle("Checkout", for: .normal)
        return button
    }()
    
    let verifyButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        button.setImage(UIImage(named: "buttonlogo"), for: .normal)
        button.setTitle("Fill form with VERIFY", for: .normal)
        button.backgroundColor = AppTheme.verifyGreen
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(onUseVerifyKeyAddressTapped(_:)), for: .touchUpInside)
        return button
    }()
    
    let poweredByLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.text = "POWERED BY"
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()
    
    let illustrationPurposes: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "For illustration purposes only"
        label.textAlignment = .center
        return label
    }()

    var typeOfSegue: String?
    var authzCode: String?
    var tokenInfo: String?
    var userInfo: String?
    let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: Foundation.OperationQueue.main)
    var dataTask: URLSessionDataTask?
    var url: URL?
    var window: UIWindow?
    var openidconfiguration: OIDServiceConfiguration?
    var carrier: String?
    var clientId: String? = "PhotoApp"
    var secret: String? = "photoapp_client_secret"
    var state: String? = ""
    var redirectUri: String? = "com.att.ent.cso.haloc.photoapp://code"
    var sharedAPI: SharedAPI?
    var carrierConfig: [String:Any]? = nil
    var scopes: [String]? = nil
    var responseTypes: [String]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        layoutView()
        
        //init shared api
        self.sharedAPI = SharedAPI()
        
        //get carrier data
        self.carrierConfig = sharedAPI!.discoverCarrierConfiguration()
        self.scopes = (carrierConfig!["scopes_supported"] as! String).components(separatedBy: " ")
        self.responseTypes = [carrierConfig!["response_types_supported"]! as! String]
        
        if let logo = UIImage(named: "carrier-logo") {
            let imageView = UIImageView(image: logo)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
            imageView.setContentCompressionResistancePriority(.required, for: .vertical)
            poweredByLabel.addSubview(imageView)
            
            imageView.leadingAnchor.constraint(equalTo: poweredByLabel.trailingAnchor, constant: 4).isActive = true
            imageView.trailingAnchor.constraint(equalTo: poweredByLabel.trailingAnchor).isActive = true
            imageView.heightAnchor.constraint(equalTo: poweredByLabel.heightAnchor).isActive = true
            imageView.centerYAnchor.constraint(equalTo: poweredByLabel.centerYAnchor).isActive = true
        } else {
            poweredByLabel.text = "Powered by \(carrier ?? "")"
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
                                        self.nameField.text = name
                                    }
                                    if let email = jsonDocument["email"].toString {
                                        self.emailField.text = email
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
        let vc = DebugViewController()
        vc.finalInit(with: DebugViewController.Info(token: tokenInfo, userInfo: userInfo, code: authzCode))
        navigationController?.pushViewController(vc, animated: true)
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
            self.nameField.text = "\(given_name) \(family_name)"
        }
        if let email = json["email"].toString {
            emailField.text = "john@email.com"
        }
         if let phone = json["phone_number"].toString {
            phoneField.text = phone
        }
        if let zip = json["postal_code"].toString {
            zipField.text = String(zip.prefix(5))
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
                                    self.cityField.text = dummyAddress
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
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        navigationItem.title = "Checkout"
        
        view.addSubview(nameField)
        view.addSubview(emailField)
        view.addSubview(phoneField)
        view.addSubview(cityField)
        view.addSubview(zipField)
        view.addSubview(requiredLabel)
        view.addSubview(checkoutButton)
        view.addSubview(verifyButton)
        view.addSubview(poweredByLabel)
        view.addSubview(illustrationPurposes)
        
        constraints.append(nameField.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 20))
        constraints.append(nameField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(nameField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        constraints.append(nameField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(emailField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 10))
        constraints.append(emailField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(emailField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        constraints.append(emailField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(phoneField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 10))
        constraints.append(phoneField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(phoneField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        constraints.append(phoneField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(cityField.topAnchor.constraint(equalTo: phoneField.bottomAnchor, constant: 10))
        constraints.append(cityField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(cityField.trailingAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor, constant: 25))
        constraints.append(cityField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(zipField.centerYAnchor.constraint(equalTo: cityField.centerYAnchor))
        constraints.append(zipField.leadingAnchor.constraint(equalTo: cityField.trailingAnchor, constant: 10))
        constraints.append(zipField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        constraints.append(zipField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(requiredLabel.topAnchor.constraint(equalTo: cityField.bottomAnchor, constant: 10))
        constraints.append(requiredLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 15))
        constraints.append(requiredLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -15))
        
        constraints.append(checkoutButton.topAnchor.constraint(equalTo: requiredLabel.bottomAnchor, constant: 20))
        constraints.append(checkoutButton.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(checkoutButton.heightAnchor.constraint(equalToConstant: 44))
        constraints.append(checkoutButton.heightAnchor.constraint(equalToConstant: 140))
        
        constraints.append(verifyButton.topAnchor.constraint(equalTo: checkoutButton.bottomAnchor, constant: 80))
        constraints.append(verifyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(verifyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(verifyButton.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(poweredByLabel.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 5))
        constraints.append(poweredByLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(poweredByLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -5))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))

        NSLayoutConstraint.activate(constraints)
        
    }
    
}
