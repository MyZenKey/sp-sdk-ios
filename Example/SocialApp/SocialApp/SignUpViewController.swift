//
//  SignUpViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class SignUpViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet var poweredByContainer: UIView!
    @IBOutlet var poweredByLabel: UILabel!
    @IBOutlet var poweredByTrailing: NSLayoutConstraint!


    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var emailIDTF: UITextField!
    @IBOutlet weak var phoneNumberTF: UITextField!
    @IBOutlet weak var passwordTF: UITextField!
    @IBOutlet weak var confirmPasswordTF: UITextField!
    
    var typeOfSegue: String?

    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set up powered by
        let carrier = Carrier()
        print("Found carrier - " + carrier.name)
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
            poweredByLabel.text = "Powered by \(carrier.name)"
        }
        
        if let url = url {
            let urlComp = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let code = urlComp?.queryItems?.filter({ $0.name == "code" }).first?.value {
                let serviceAPIObject = ServiceAPI()
                serviceAPIObject.login(with: code, completionHandler: { (result) in
                    if let accessToken = result["access_token"].toString {
                        serviceAPIObject.getUserInfo(with: accessToken, completionHandler: {(userInfoResponse) in
                            self.displayUserInfo(from: userInfoResponse)
                        })
                    }
                } )
            }
        }
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Cancel", style: UIBarButtonItemStyle.plain, target: self, action: #selector(backButtonAction(sender:)))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
        updateNavigationThemeColor()
        // Do any additional setup after loading the view.
    }
    
   
    @objc func  backButtonAction(sender : Any) {
        self.navigationController!.dismiss(animated: true, completion: nil)
    }

    func displayUserInfo(from json: JsonDocument) {
        
        if let phone = json["phone_number"].toString {
            self.phoneNumberTF.text = phone
        }
        
        if let family_name = json["family_name"].toString, let given_name = json["given_name"].toString {
            self.nameTF.text = "\(given_name) \(family_name)"
        }
        
        if let email = json["email"].toString {
            self.emailIDTF.text = email
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        
        nameTF.delegate = self;
        emailIDTF.delegate = self;
        phoneNumberTF.delegate = self;
        passwordTF.delegate = self;
        confirmPasswordTF.delegate = self;

    }
    
    /// Launches the Verify app.
    @IBAction func signUpWithVerify() {
        //Set AppDelegate launchMapViewFlag to False to open current form page
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.launchMapViewFlag = false
        
        // custom URL scheme
        if let url = URL(string: "\(AppConfig.AuthorizeURL)?client_id=\(AppConfig.clientID.urlEncode())&response_type=code&state=teststate&redirect_uri=\(AppConfig.code_redirect_uri.urlEncode())&scope=\(AppConfig.consentScope.urlEncode())") {
            
            UIApplication.shared.open(url, options: [:]) { [weak self] success in
                print(success)
                
                if success {
                    NSLog("Successful!")
                } else {
                    self?.showOkAlert(title: "Sorry, looks like something went wrong. Please try again.", message: nil)
                }
            }
        }
    }
    
    @IBAction func SignUpBTN(_ sender: Any) {
        self.checkValidation()
    }
    
    func checkValidation() {
        if (nameTF.text?.isEmpty)! || (emailIDTF.text?.isEmpty)! || (phoneNumberTF.text?.isEmpty)! || (passwordTF.text?.isEmpty)! || (confirmPasswordTF.text?.isEmpty)!
        {
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelButton() {
        self.navigationController!.dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
