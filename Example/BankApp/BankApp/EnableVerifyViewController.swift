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

    let gradientView: GradientView = {
        let gradientView = GradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()
    
    let logo: UIImageView = {
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "applogo_white")
        logo.contentMode = .scaleAspectFit
        return logo
    }()
    
    let enableButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("YES", for: .normal)
        button.addTarget(self, action: #selector(enableVerify(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0)
        return button
    }()
    
    let cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("No, thanks", for: .normal)
        button.addTarget(self, action: #selector(cancelVerify(_:)), for: .touchUpInside)
        button.setTitleColor(UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0), for: .normal)

        return button
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let text = "We now support\nProject Verify"
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([NSAttributedStringKey.font :  UIFont.italicSystemFont(ofSize: 38), NSAttributedStringKey.foregroundColor:UIColor.black], range: (text as NSString).range(of: "Project Verify"))
        label.attributedText = attributedString
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        let text = "Would you like to use Project Verify to approve future Bank App logins?"
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttributes([NSAttributedStringKey.font :  UIFont.italicSystemFont(ofSize: 18), NSAttributedStringKey.foregroundColor:UIColor.black], range: (text as NSString).range(of: "Project Verify"))
        label.attributedText = attributedString
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    var openidconfiguration: OIDServiceConfiguration?
    var carrier: String?
    var clientId: String? = "BankApp"
    var secret: String? = "bankapp_client_secret"
    var state: String? = ""
    var redirectUri: String? = "com.att.ent.cso.haloc.bankapp://code"
    var sharedAPI: SharedAPI?
    var carrierConfig: [String:Any]? = nil
    var scopes: [String]? = nil
    var responseTypes: [String]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
        
        //init shared api
        self.sharedAPI = SharedAPI()
        
        //get carrier data
        self.carrierConfig = sharedAPI!.discoverCarrierConfiguration()
        self.scopes = (carrierConfig!["scopes_supported"] as! String).components(separatedBy: " ")
        self.responseTypes = [carrierConfig!["response_types_supported"]! as! String]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func cancelVerify(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func enableVerify(_ sender: Any) {
        
        navigationController?.pushViewController(HomeViewController(), animated: true)
        
//        //check if carrier config is nil
//        if self.carrierConfig != nil {
//            print("Found value carrier configuration. Setting auth and token urls in openid config")
//            //init service configuration object
//            let authorizationUrlString: String? = self.carrierConfig!["authorization_endpoint"] as! String
//            let tokenUrlString:String? = self.carrierConfig!["token_endpoint"] as! String
//            let authorizationURL: URL = URL(string: authorizationUrlString!)!
//            let tokenURL:URL = URL(string: tokenUrlString!)! as! URL
//            self.openidconfiguration = OIDServiceConfiguration.init(authorizationEndpoint: authorizationURL, tokenEndpoint: tokenURL)
//
//            //create the authorization request
//            let authorizationRequest:OIDAuthorizationRequest = self.createAuthorizationRequest(scopes: self.scopes!, responseType: self.responseTypes!)!
//            print("Authorization Request created")
//
//            //check to see if the authorization url is set as a universal app link
//            UIApplication.shared.open(authorizationURL, options: [UIApplicationOpenURLOptionUniversalLinksOnly: true], completionHandler: { success in
//                if success {
//                    print("This url can be opened in an app. Launching app...")
//                    self.initProjectVerifyAuthorization(request: authorizationRequest)
//                }
//                else {
//                    print("Launching default safari controller process...")
//                    self.performAuthorization(request: authorizationRequest)
//                }
//            })
//        }
//        else {
//            print("Carrier Config is null. Cannot perform authentication")
//        }
        
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

    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let marginGuide = view.safeAreaLayoutGuide
        
        
        view.addSubview(gradientView)
        view.addSubview(logo)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(enableButton)
        view.addSubview(cancelButton)
        
        constraints.append(NSLayoutConstraint(item: gradientView,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(NSLayoutConstraint(item: gradientView,
                                              attribute: .width,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .width,
                                              multiplier: 1,
                                              constant: 0))
        gradientView.heightAnchor.constraint(equalToConstant: 70).isActive = true
        
        constraints.append(NSLayoutConstraint(item: logo,
                                              attribute: .centerY,
                                              relatedBy: .equal,
                                              toItem: gradientView,
                                              attribute: .centerY,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(NSLayoutConstraint(item: logo,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        logo.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        constraints.append(NSLayoutConstraint(item: titleLabel,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: gradientView,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 100))
        constraints.append(NSLayoutConstraint(item: titleLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: titleLabel,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        
        
        constraints.append(NSLayoutConstraint(item: descriptionLabel,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: titleLabel,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))
        constraints.append(NSLayoutConstraint(item: descriptionLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: descriptionLabel,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        
        constraints.append(NSLayoutConstraint(item: cancelButton,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: -25))
        constraints.append(NSLayoutConstraint(item: cancelButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 48))
        constraints.append(NSLayoutConstraint(item: cancelButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -48))
        cancelButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        constraints.append(NSLayoutConstraint(item: enableButton,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: cancelButton,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: -25))
        constraints.append(NSLayoutConstraint(item: enableButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 48))
        constraints.append(NSLayoutConstraint(item: enableButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -48))
        enableButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        NSLayoutConstraint.activate(constraints)
        
    }
}
