//
//  ViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
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
        let button = ProjectVerifyBrandedButton()
        button.translatesAutoresizingMaskIntoConstraints = false
//        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
//        button.setImage(UIImage(named: "buttonlogo"), for: .normal)
//        button.setTitle("Sign in with VERIFY", for: .normal)
//        button.backgroundColor = AppTheme.verifyGreen
//        button.layer.masksToBounds = true
//        button.layer.cornerRadius = 22
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
    let authService = AuthorizationService()
    let serviceAPI = ServiceAPI()

    /// Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
        
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
        let scopes: [Scope] = [.profile, .email]
        authService.connectWithProjectVerify(
            scopes: scopes,
            fromViewController: self) { result in
                // TODO: login + fetch user
                // TODO: - fix this up, shouldn't be digging into app delegate but quickest refactor
                let appDelegate = UIApplication.shared.delegate! as! AppDelegate
                switch result {
                case .code(let authorizedResponse):
                    let code = authorizedResponse.code

                    UserDefaults.standard.set(code, forKey: "AuthZCode")
                    self.serviceAPI.login(
                        withAuthCode: code,
                        mcc: authorizedResponse.mcc,
                        mnc: authorizedResponse.mnc,
                        completionHandler: { json, error in
                            print("AuthZ_Code value from is: \(code)\n")
                            UserDefaults.standard.set(code,forKey: "AuthZCode")
                            guard let token = json?["token"].toString else {
                                print("expected token returned")
                                return
                            }

                            if (appDelegate.launchMapViewFlag) {
                                appDelegate.launchMapScreen(token: token)
                            } else {
                                appDelegate.launchSignUpScreen(token: token)
                            }

                    })

                case .error:
                    appDelegate.launchLoginScreen()
                case .cancelled:
                    appDelegate.launchLoginScreen()
                }
        }
    }
        // TODO: reimplement this once we have a demo backend
        // old post auth logic for fetching user:
//                /*//init view controller for user info
//                let url = self.redirectUri! + "?code=" + authorizationCode!
//                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserInfoViewController") as! UserInfoViewController
//                vc.url = URL(string: url)
//                self.navigationController?.viewControllers.removeAll()
//                self.navigationController?.viewControllers.append(vc)
//                print("view controller loaded")*/
//
//                //perform a simple GET request to gather the user information
//                let userInfoUrl = URL(string: self.carrierConfig!["userinfo_endpoint"] as! String)
//                let request = NSMutableURLRequest(url: userInfoUrl! as URL)
//                request.httpMethod = "GET"
//                request.setValue("Bearer " + accessToken!, forHTTPHeaderField: "Authorization")
//                let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
//                    print("User information response has returned - ")
//                    if(error == nil) {
//                        if let res = response as? HTTPURLResponse {
//                            print(res)
//                            let responseString = String(data: data!, encoding:String.Encoding.utf8) as String!
//                            print(responseString)
//
//                            do{
//                                //convert the json string to pure json
//                                if let json = responseString!.data(using: String.Encoding.utf8){
//                                    let jsonDocument:JsonDocument = JsonDocument(data: json)
//                                    //perform async task to update UI
//                                    DispatchQueue.main.async {
//                                        //redirect to the user view controller
//                                        print("Redirecting to userinfo view controller")
//                                        let vc = UserInfoViewController()
//                                        vc.userInfoJson = jsonDocument
//                                        self.navigationController?.pushViewController(vc, animated: true)
//                                    }
//                                }
//                            }catch {
//                                print(error.localizedDescription)
//                            }
//                        }
//                    }
//                    else {
//                        print(error)
//                    }
//                }
//                task.resume()

//    //this function will convert the incoming json string to dictionary
//    func convertToDictionary(text: String) -> [String: Any]? {
//        if let data = text.data(using: .utf8) {
//            do {
//                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
//        return nil
//    }

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
