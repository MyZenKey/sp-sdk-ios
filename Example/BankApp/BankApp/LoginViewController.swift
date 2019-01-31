//
//  LoginViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet fileprivate weak var forgotButton: UIButton!
    @IBOutlet fileprivate weak var registerButton: UIButton!
    @IBOutlet fileprivate weak var idTextField: UITextField!
    @IBOutlet fileprivate weak var passwordTextField: UITextField!
    @IBOutlet weak var forgotTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var registerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var disclaimerBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        idTextField.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            
            forgotTopConstraint.constant = 16
            registerTopConstraint.constant = 16
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            disclaimerBottomConstraint.constant = keyboardHeight + 8
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {

        forgotTopConstraint.constant = 33
        registerTopConstraint.constant = 33
        disclaimerBottomConstraint.constant = 12
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        idTextField.becomeFirstResponder()
    }
    
    @IBAction func onLoginButtonTouched(_ sender: Any) {
        // TODO: see UX section 2.3.1 in design doc
        // Does SP have this ID associated with CCID (Verify)?
        //   No - show Enable Verify screen, then go to sub-flow 2.0.3 in Verify
        //   Yes - go directly to sub-flow 2.0.3 in Verify
        performSegue(withIdentifier: "segueEnableVerify", sender: self)
    }
    
    @IBAction func onSignInWithVerifyTouched(_ sender: Any) {
        // TODO: see UX section 2.3.1 in design doc
        // Does SP have this ID associated with CCID (Verify)?
        //   No - show Enable Verify screen, then go to sub-flow 2.0.3 in Verify
        //   Yes - go directly to sub-flow 2.0.3 in Verify
        performSegue(withIdentifier: "segueEnableVerify", sender: self)
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
