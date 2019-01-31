//
//  SigninViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class SigninViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var view_signinVerify: UIView!
    @IBOutlet weak var view_signinSharingApp: UIView!
    @IBOutlet weak var btn_signin: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view_signinVerify.layer.cornerRadius = 5.0;
        view_signinSharingApp.layer.cornerRadius = 5.0;
        btn_signin.layer.cornerRadius = 5.0;

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}
