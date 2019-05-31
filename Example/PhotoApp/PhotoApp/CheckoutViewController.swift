//
//  CheckoutViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import CarriersSharedAPI

class CheckoutViewController: UIViewController {
    
    let nameField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Name"
        return field
    }()
    
    let emailField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Email"
        return field
    }()
    
    let phoneField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "Phone"
        return field
    }()
    
    let cityField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
        field.borderStyle = .roundedRect
        field.placeholder = "City, State"
        return field
    }()
    
    let zipField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.layer.borderColor =  UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1.0).cgColor
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

    var authzCode: String?
    var tokenInfo: String?
    var userInfo: String?
    let session = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: Foundation.OperationQueue.main)
    var dataTask: URLSessionDataTask?
    var window: UIWindow?

    var carrier: String? = "TODO: Carrier"
    let authService = AuthorizationService()
    let serviceAPI = ServiceAPI()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        layoutView()
        
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onUseVerifyKeyAddressTapped(_ sender: Any) {
        // Request an authorization code from Project Verify:
        let scopes: [Scope] = [.profile, .email]
        authService.authorize(
            scopes: scopes,
            fromViewController: self) { result in
                // handle the result of the authorization call
                switch result {
                case .code(let authorizedResponse):
                    self.authorizeUser(authorizedResponse: authorizedResponse)
                case .error:
                    self.launchLoginScreen()
                case .cancelled:
                    self.launchLoginScreen()
                }
        }
    }

    func authorizeUser(authorizedResponse: AuthorizedResponse) {
        let code = authorizedResponse.code
        UserDefaults.standard.set(code, forKey: "AuthZCode")
        self.serviceAPI.login(
            withAuthCode: code,
            mcc: authorizedResponse.mcc,
            mnc: authorizedResponse.mnc,
            completionHandler: { json, error in
                guard
                    let accountToken = json?["token"],
                    let tokenString = accountToken.toString else {
                        print("error no token returned")
                        return
                }
                UserDefaults.standard.set(tokenString, forKey: "AccessToken")

                self.requestUserInfo(token: tokenString)
        })
    }

    func requestUserInfo(token: String) {
        self.serviceAPI.getUserInfo(with: token) { userJSON in
            self.displayUserInfo(from: userJSON)
        }
    }

    func launchLoginScreen() {
        // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
        let appDelegate = UIApplication.shared.delegate! as! AppDelegate
        appDelegate.launchLoginScreen()
    }

    @IBAction func debug() {
        let vc = DebugViewController()
        vc.finalInit(with: DebugViewController.Info(token: tokenInfo, userInfo: userInfo, code: authzCode))
        navigationController?.pushViewController(vc, animated: true)
    }

    func displayUserInfo(from json: JsonDocument){
        print("Populating user information..")
        self.userInfo = json.description
       
        if let family_name = json["family_name"].toString, let given_name = json["given_name"].toString {
            self.nameField.text = "\(given_name) \(family_name)"
        }
        if let email = json["email"].toString {
            emailField.text = email
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
