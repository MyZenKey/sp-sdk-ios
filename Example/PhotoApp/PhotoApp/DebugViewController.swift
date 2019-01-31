//
//  DebugViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit
import MapKit

class DebugViewController: UIViewController {

    @IBOutlet var tokenLabel: UILabel!
    @IBOutlet var tokenValue: UILabel!
    @IBOutlet var userInfoLabel: UILabel!
    @IBOutlet var userInfoValue: UILabel!
    @IBOutlet var AuthZCodeLabel: UILabel!
    @IBOutlet var AuthZCodeValue: UILabel!
    

    struct Info {
        let token: String?
        let userInfo: String?
        let code: String?
    }

    var debug: Info?

    func finalInit(with debug: Info) {
        self.debug = debug
    }

    /// Do any additional setup after loading the view.
    override func viewDidLoad() {
        super.viewDidLoad()

        if let debug = debug {
            if let token = debug.token {
                tokenValue.text = token
                print(token)
            }
            if let userInfo = debug.userInfo {
                userInfoValue.text = userInfo
                print(userInfo)
            }
            if let authZcode = debug.code {
                AuthZCodeValue.text = authZcode
                print(authZcode)
            }
        }
    }

    @IBAction func clear() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.logout()
        }
    }
    
    @IBAction func done() {
        dismiss(animated: true, completion: nil)
    }
}
