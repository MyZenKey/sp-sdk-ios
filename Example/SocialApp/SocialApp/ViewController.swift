//
//  ViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import AppAuth
import CarriersSharedAPI

class ViewController: UIViewController, UITextFieldDelegate {
    
    let logo: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.image = UIImage(named: "icon_Socialapp")
        img.contentMode = .scaleAspectFit
        return img
    }()
    
    let nameField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.cornerRadius = 2.0
        field.layer.borderWidth = 1.0
        field.placeholder = "Email or Phone"
        return field
    }()
    
    let passwordField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.layer.borderWidth = 1.0
        field.layer.cornerRadius = 2.0
        field.placeholder = "Password"
        return field
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Sign up", for: .normal)
        button.backgroundColor = AppTheme.themeColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 7.0
        button.addTarget(self, action: #selector(signUpPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    let loginButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = AppTheme.themeColor
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 7.0
        return button
    }()
    
    let orLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "OR"
        label.textAlignment = .center
        return label
    }()
    
    let verifyButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        button.setImage(UIImage(named: "buttonlogo"), for: .normal)
        button.setTitle("Sign in with VERIFY", for: .normal)
        button.backgroundColor = AppTheme.verifyGreen
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(signInWithVerify), for: .touchUpInside)
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
    
    var window: UIWindow?
    var openidconfiguration: OIDServiceConfiguration?
    var carrier:String?
    var clientId:String? = "SocialApp"
    var secret:String? = "socialapp_client_secret"
    var state:String? = ""
    var redirectUri:String? = "com.att.ent.cso.haloc.socialapp://code"
    var sharedAPI:SharedAPI?
    var carrierConfig:[String:Any]? = nil
    var scopes:[String]? = nil
    var responseTypes:[String]? = nil
    var application:UIApplication?
    
    /// Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
        
        //init shared api
        self.sharedAPI = SharedAPI()
        
        // set up powered by
        let carrier = Carrier()
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
            poweredByLabel.text = "Powered by \(carrier.name)"
        }
        updateNavigationThemeColor()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func signUpPressed(_: UIButton) {
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    /// Launches the Verify app.
    @objc func signInWithVerify() {
        
        //get carrier data
        self.carrierConfig = sharedAPI!.discoverCarrierConfiguration()
        self.scopes = (carrierConfig!["scopes_supported"] as! String).components(separatedBy: " ")
        self.responseTypes = [carrierConfig!["response_types_supported"]! as! String]

        //check if carrier config is nil
        if self.carrierConfig != nil {
            print("Found value carrier configuration. Setting auth and token urls in openid config")
            //init service configuration object
            let authorizationUrlString:String? = self.carrierConfig!["authorization_endpoint"] as! String
            let tokenUrlString:String? = self.carrierConfig!["token_endpoint"] as! String
            let authorizationURL:URL = URL(string: authorizationUrlString!)!
            let tokenURL:URL = URL(string: tokenUrlString!)!
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
        
        /*self.carrierConfig = sharedAPI!.discoverCarrierConfiguration()
        var urlStr:String = self.carrierConfig!["authorization_endpoint"] as! String
        let consentUrlString = "\(urlStr)?client_id=\(AppConfig.clientID.urlEncode())&response_type=code&state=teststate&redirect_uri=\(AppConfig.code_redirect_uri.urlEncode())&scope=\(AppConfig.consentScope.urlEncode())"*/
        
//        // URL scheme: com.att.ent.cso.haloc.consent
//        let destinationUrl = consentUrlString.data(using: String.Encoding.utf8)?.base64EncodedString() ?? ""
//        if let url = URL(string: "com.att.ent.cso.haloc.consent://\(destinationUrl)") {
//
//            // TODO: Figure out why canOpenURL() is false?
//
//            UIApplication.shared.open(url, options: [:]) { success in
//                if success {
//                    NSLog("Successful!")
//                }
//            }
//            return
//        }

        /*//Set AppDelegate launchMapViewFlag to True to open MapView page
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.launchMapViewFlag = true
        
        
        // custom URL scheme
        let consentUrlString = self.carrierConfig!["authorization_endpoint"] as! String*/
        /*if let url = URL(string: consentUrlString) {

            UIApplication.shared.open(url, options: [UIApplicationOpenURLOptionUniversalLinksOnly: true]) { [weak self] success in
                if success {
                    NSLog("Successful!")
                } else {
//                    UIApplication.shared.open(url, options: [:]) { success in
//                        NSLog("Successful for non-Universal Link? \(success)")
//                    }
                    self?.showOkAlert(title: "Sorry, looks like something went wrong. Please try again.", message: nil)
                }
            }
        }*/
    }
    
    //this function will initialize the authorization request
    func createAuthorizationRequest(scopes: [String], responseType: [String]) -> OIDAuthorizationRequest? {
        
        //init the authorization redirect
        let redirectUrl:URL? = URL(string: self.redirectUri!) as! URL
        
        //init extra params
        let _:[String:String] = [String:String]()
        
        //compile request
        do {
            let request:OIDAuthorizationRequest = OIDAuthorizationRequest.init(configuration: self.openidconfiguration!, clientId: self.clientId!, clientSecret: self.secret, scope: self.scopes!.joined(separator: " "), redirectURL: redirectUrl, responseType: responseType[0], state: "", nonce: nil, codeVerifier: nil, codeChallenge: nil, codeChallengeMethod: nil, additionalParameters: nil)
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
        let url:String = self.carrierConfig!["authorization_endpoint"] as! String
        let scopes = self.carrierConfig!["scopes_supported"] as! String
        let consentUrlString = "\(url)?client_id=\(clientId!.urlEncode())&response_type=code&redirect_uri=\(redirectUri!.urlEncode())&scope=\(scopes.urlEncode())"
        print("Checking if " + consentUrlString + " is part of a universal link")
        var _:Optional<URL> = URL(string:consentUrlString)
        let urlTransformation = OIDExternalUserAgentIOSCustomBrowser.urlTransformationSchemeConcatPrefix(consentUrlString)
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
                _ = authState!.lastAuthorizationResponse.authorizationCode
                let accessToken = authState?.lastTokenResponse?.accessToken
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
                            
                            do{
                                //convert the json string to pure json
                                if let json = responseString!.data(using: String.Encoding.utf8){
                                    let jsonDocument:JsonDocument = JsonDocument(data: json)
                                    //perform async task to update UI
                                    DispatchQueue.main.async {
                                        //redirect to the user view controller
                                        print("Redirecting to userinfo view controller")
                                        let vc = UserInfoViewController()
                                        vc.userInfoJson = jsonDocument
                                        self.navigationController?.pushViewController(vc, animated: true)
                                    }
                                }
                            }catch {
                                print(error.localizedDescription)
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
    
    //this function will convert the incoming json string to dictionary
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        view.addSubview(logo)
        view.addSubview(nameField)
        view.addSubview(passwordField)
        view.addSubview(signUpButton)
        view.addSubview(loginButton)
        view.addSubview(orLabel)
        view.addSubview(verifyButton)
        view.addSubview(poweredByLabel)
        view.addSubview(illustrationPurposes)
        
        constraints.append(logo.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 100))
        constraints.append(logo.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        
        constraints.append(nameField.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 65))
        constraints.append(nameField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(nameField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(nameField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(passwordField.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 15))
        constraints.append(passwordField.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(passwordField.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(passwordField.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(signUpButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 15))
        constraints.append(signUpButton.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor))
        constraints.append(signUpButton.trailingAnchor.constraint(equalTo: passwordField.centerXAnchor, constant: -7.5))
        constraints.append(signUpButton.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 15))
        constraints.append(loginButton.leadingAnchor.constraint(equalTo: passwordField.centerXAnchor, constant: 7.5))
        constraints.append(loginButton.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor))
        constraints.append(loginButton.heightAnchor.constraint(equalToConstant: 44))

        constraints.append(orLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 25))
        constraints.append(orLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(orLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        
        constraints.append(verifyButton.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 25))
        constraints.append(verifyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(verifyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        constraints.append(verifyButton.heightAnchor.constraint(equalToConstant: 44))
        
        constraints.append(poweredByLabel.topAnchor.constraint(equalTo: verifyButton.bottomAnchor, constant: 5))
        constraints.append(poweredByLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 30))
        constraints.append(poweredByLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -30))
        
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
        
    }
}
