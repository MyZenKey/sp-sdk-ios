//
//  ApproveViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class ApproveViewController: UIViewController {
    
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
    
    let promptLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Would you like to transfer $100.00 to nmel1234?"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let yesButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Yes", for: .normal)
        button.addTarget(self, action: #selector(initiateTransfer(_:)), for: .touchUpInside)
        button.backgroundColor = AppTheme.primaryBlue
        return button
    }()
    
    let cancelButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelTransaction(_:)), for: .touchUpInside)
        button.backgroundColor = AppTheme.primaryBlue
        return button
    }()
    
    
    private var notification: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        layoutView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func cancelTransaction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func handleNotification() {
        notification = NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: .main) {
            [unowned self] notification in
            
//            if UserDefaults.standard.bool(forKey: "initiatedTransfer") {
//                UserDefaults.standard.set(false, forKey: "initiatedTransfer")
//                UserDefaults.standard.synchronize()
//                //self.performSegue(withIdentifier: "segueTransferComplete", sender: nil)
//            }
            // do whatever you want when the app is brought back to the foreground
        }
    }
    deinit {
        // make sure to remove the observer when this view controller is dismissed/deallocated
        if let notification = notification {
            NotificationCenter.default.removeObserver(notification)
        }
    }
    
    @objc func initiateTransfer(_ sender: Any) {
        //self.view.showActivityIndicator()
        navigationController?.pushViewController(EnterPINViewController(), animated: true)
//        let authService = AuthService()
//
//        authService.authorize(serialNumber: AppConfig.UUID, sucess: { [weak self] (success) in
//
//            self?.view.hideActivityIndicator()
//            if  let status = success["status"] as? Bool{
//                UserDefaults.standard.set(true, forKey: "initiatedTransfer");
//                UserDefaults.standard.set(false, forKey: "transaction_denied")
//
//                UserDefaults.standard.synchronize()
//                self?.handleNotification()
//                if status{
//                    //Call Verify App
//                }else{
//
//                }
//            }
//        }) { (error) in
//
//        }
//        EnterPINViewController.presentPINScreen(on: self) { [weak self] (success) in
//            if success {
//                self?.performSegue(withIdentifier: "segueTransferComplete", sender: self)
//            }
//        }
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let marginGuide = view.safeAreaLayoutGuide
        
        
        view.addSubview(gradientView)
        view.addSubview(logo)
        view.addSubview(promptLabel)
        view.addSubview(yesButton)
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
        
        constraints.append(NSLayoutConstraint(item: promptLabel,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: gradientView,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 100))
        constraints.append(NSLayoutConstraint(item: promptLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: promptLabel,
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
                                              constant: -30))
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
        
        constraints.append(NSLayoutConstraint(item: yesButton,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: cancelButton,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: -10))
        constraints.append(NSLayoutConstraint(item: yesButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 48))
        constraints.append(NSLayoutConstraint(item: yesButton,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: marginGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -48))
        yesButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        NSLayoutConstraint.activate(constraints)
        
    }

}
