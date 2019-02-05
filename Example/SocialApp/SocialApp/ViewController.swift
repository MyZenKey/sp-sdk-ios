//
//  ViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import AppAuth
import CarriersSharedAPI

class ViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var label: UILabel!
    @IBOutlet var button: UIButton!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet weak var tf_name: UITextField!
    @IBOutlet weak var tf_password: UITextField!
    @IBOutlet var poweredByContainer: UIView!
    @IBOutlet var poweredByLabel: UILabel!
    @IBOutlet var poweredByTrailing: NSLayoutConstraint!
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
        
        //init shared api
        self.sharedAPI = SharedAPI()
        
        tf_name.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        tf_name.layer.cornerRadius = 2.0
        tf_name.layer.borderWidth = 1.0
        tf_password.layer.borderColor =  UIColor.init(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        tf_password.layer.borderWidth = 1.0
        tf_password.layer.cornerRadius = 2.0
        signInButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
        
        // set up powered by
        //let carrier = Carrier()
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
            //poweredByLabel.text = "Powered by \(auth.carrierName())"
        }
        updateNavigationThemeColor()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let typeOfSegue: String = "push"
        
        if (segue.identifier == "push") {
            let vc = segue.destination as! SignUpViewController
            vc.typeOfSegue = typeOfSegue
        }
        
    }

    /// Launches the Verify app.
    @IBAction func signInWithVerify() {
        
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
                                        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserInfoViewController") as! UserInfoViewController
                                        vc.userInfoJson = jsonDocument
                                        self.present(vc, animated: true, completion: nil)
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
}
