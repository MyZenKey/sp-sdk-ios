//
//  ApproveViewController.swift
//  BankApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class ApproveViewController: UIViewController {

    @IBOutlet fileprivate weak var promptLabel: UILabel!
    @IBOutlet fileprivate weak var yesButton: UIButton!
    @IBOutlet fileprivate weak var cancelButton: UIButton!
    private var notification: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true

        setupPrompt()
        setupButtons()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelTransaction(_ sender: Any) {
        self.goBack()
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
    @IBAction func initiateTransfer(_ sender: Any) {
        self.view.showActivityIndicator()
        /*let authService = AuthService();
        print(AppConfig.UUID)
        authService.authorize(serialNumber: AppConfig.UUID, sucess: { [weak self] (success) in
            
            self?.view.hideActivityIndicator()
            if  let status = success["status"] as? Bool{
                UserDefaults.standard.set(true, forKey: "initiatedTransfer");
                UserDefaults.standard.set(false, forKey: "transaction_denied")
                
                UserDefaults.standard.synchronize()
                self?.handleNotification()
                if status{
                    //Call Verify App
                }else{
                    
                }
            }
        }) { (error) in

        }*/
        /*EnterPINViewController.presentPINScreen(on: self) { [weak self] (success) in
            if success {
                self?.performSegue(withIdentifier: "segueTransferComplete", sender: self)
            }
        }*/
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

// MARK: Private

private extension ApproveViewController {
    
    func setupPrompt() {
        promptLabel.text = "Would you like to\ntransfer $100.00 to\nmel1234?"
    }
    
    func setupButtons() {
        yesButton.layer.cornerRadius = yesButton.frame.size.height/2.0
        yesButton.layer.borderWidth = 1.0
        yesButton.layer.borderColor = yesButton.backgroundColor?.cgColor
        cancelButton.layer.cornerRadius = cancelButton.frame.size.height/2.0
        cancelButton.layer.borderWidth = 1.0
        cancelButton.layer.borderColor = cancelButton.backgroundColor?.cgColor
    }
}
