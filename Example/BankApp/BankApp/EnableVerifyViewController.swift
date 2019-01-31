//
//  EnableVerifyViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import AppAuth
import CarriersSharedAPI

class EnableVerifyViewController: UIViewController {
    @IBOutlet weak var btn_cancel: UIButton!
    @IBOutlet weak var btn_enable: UIButton!
    @IBOutlet weak var lbl_description: UILabel!
    var openidconfiguration: OIDServiceConfiguration?
    var carrier:String?
    var clientId:String? = "BankApp"
    var secret:String? = "bankapp_client_secret"
    var state:String? = ""
    var redirectUri:String? = "com.att.ent.cso.haloc.bankapp://code"
    var sharedAPI: SharedAPI?
    var carrierConfig:[String:Any]? = nil
    var scopes:[String]? = nil
    var responseTypes:[String]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btn_enable.layer.cornerRadius = btn_enable.frame.size.height/2.0
        
        //init shared api
        self.sharedAPI = SharedAPI()
        
        //get carrier data
        self.carrierConfig = sharedAPI!.discoverCarrierConfiguration()
        self.scopes = (carrierConfig!["scopes_supported"] as! String).components(separatedBy: " ")
        self.responseTypes = [carrierConfig!["response_types_supported"]! as! String]
        
//        self.navigationController?.isNavigationBarHidden = false
        // Do any additional setup after loading the view.
        if let text = lbl_description.text{
            let attributedString = NSMutableAttributedString(string:text)
            attributedString.addAttributes([NSAttributedStringKey.font :  UIFont.italicSystemFont(ofSize: 18), NSAttributedStringKey.foregroundColor:UIColor.black], range: (text as NSString).range(of: "Project Verify"))
            lbl_description.attributedText = attributedString
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelVerify(_ sender: Any) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.launchLoginScreen()
        }
    }
    
    @IBAction func enableVerify(_ sender: Any) {
        
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
        
        /*let consentUrlString = "\(AppConfig.AuthorizeURL)?client_id=\(AppConfig.clientID.urlEncode())&response_type=code&state=teststate&redirect_uri=\(AppConfig.code_redirect_uri.urlEncode())&scope=\(AppConfig.consentScope.urlEncode())"
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.launchMapViewFlag = true
        
        // custom URL scheme
        if let url = URL(string: consentUrlString) {
            
            UIApplication.shared.open(url, options: [UIApplicationOpenURLOptionUniversalLinksOnly: true]) { [weak self] success in
                if success {
                    NSLog("Successful!")
                } else {
//                    UIApplication.shared.open(url, options: [:]) { success in
//                        NSLog("Successful for non-Universal Link? \(success)")
//                    }
                    // "Sorry, looks like something went wrong. Please try again."
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
                                    var jsonDocument:JsonDocument = JsonDocument(data: json)
                                    //perform async task to update UI
                                    DispatchQueue.main.async {
                                        let storyboard = UIStoryboard(name:"Main", bundle: nil)
                                        let homeVC = storyboard.instantiateViewController(withIdentifier: "homeScene")
                                        let appDelegate = UIApplication.shared.delegate as? AppDelegate
                                        appDelegate!.window?.rootViewController = homeVC
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
