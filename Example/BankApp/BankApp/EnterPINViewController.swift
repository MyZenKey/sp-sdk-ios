//
//  EnterPINViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class EnterPINViewController: UIViewController {
    
    @IBOutlet weak var backButtonBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var illustrationBottomContraint: NSLayoutConstraint!

    // The six dots
    @IBOutlet fileprivate weak var dotView0: DotView!
    @IBOutlet fileprivate weak var dotView1: DotView!
    @IBOutlet fileprivate weak var dotView2: DotView!
    @IBOutlet fileprivate weak var dotView3: DotView!
    @IBOutlet fileprivate weak var dotView4: DotView!
    @IBOutlet fileprivate weak var dotView5: DotView!
    
    fileprivate var dotViews:[DotView] = []
    fileprivate var numDigits = 0
    fileprivate var completionHandler:((Bool)->Void)?
    
    // This is the receiver for user input
    fileprivate var hiddenInputTextField: UITextField!
    
    fileprivate var enteredPIN: String = ""
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowHide(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowHide(_:)), name: .UIKeyboardWillHide, object: nil)
        
        setupInputField()
        setupDots()
        applyAppTheme()
    }
    
    @objc func keyboardWillShowHide(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            
            // Animate the "< Back" button up or down based on whether keyboard was shown or hidden.
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            backButtonBottomContraint.constant = keyboardHeight + 34
            illustrationBottomContraint.constant = keyboardHeight  + 12
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        clearPIN()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        hiddenInputTextField.becomeFirstResponder()
    }
    
    @IBAction func onBackButtonTouched(_ sender: Any) {
        completionHandler?(false)
        goBack()
        //self.navigationController?.popViewController(animated: true)
        //navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//
//    }
    
}

// MARK: - UITextFieldDelegate

extension EnterPINViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.count == 0 {
            // Backspace on the num pad - delete last entry
            if enteredPIN.count > 0 {
                enteredPIN.deleteLastChar()
            }
        } else {
            
            if enteredPIN.count < numDigits {
                enteredPIN += string
            }
            
            if enteredPIN.count == numDigits {
                
                if validateEnteredPIN() {
                    if let handler = completionHandler {
                        self.dismiss(animated: true) {
                            handler(true)
                        }
                    }
                } else {
                    // TODO: Some sort of message
                    clearPIN()
                }
                
            }
        }
        updateDots()
        
        debugPrint("enteredPIN: \(enteredPIN)")
        return true
    }
}

// MARK: - Private

private extension EnterPINViewController {
    
    func setupInputField() {
        hiddenInputTextField = UITextField(frame: CGRect(x: -10, y: -10, width: 1, height: 1))
        hiddenInputTextField.keyboardType = .numberPad
        hiddenInputTextField.delegate = self
        self.view.addSubview(hiddenInputTextField)
    }
    
    func setupDots() {
        dotViews = [dotView0, dotView1, dotView2, dotView3, dotView4, dotView5]
        numDigits = dotViews.count
    }
    
    func updateDots() {
        var index = 0
        let pinLength = enteredPIN.count
        dotViews.forEach { (dotView) in
            dotView.empty = index >= pinLength
            index += 1
        }
    }
    
    func applyAppTheme() {

    }
    
    func clearPIN() {
        enteredPIN = ""
        updateDots()
    }
    
    func validateEnteredPIN() -> Bool {
        
        // TODO: Validate against previously stored PIN
        
        return true
    }
}

// MARK: - Factory methods

extension EnterPINViewController {
    
    class func create() -> EnterPINViewController {
        
        let storyboard = UIStoryboard(name:"Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "enterPinScene") as? EnterPINViewController else {
            fatalError("Failed to instantiate a EnterPINViewController from Main.storyboard")
        }
        
        return vc
    }
    
    class func presentPINScreen(on vc: UIViewController, completionHandler:@escaping (Bool)->Void) {
        let enterPinVC = EnterPINViewController.create()
        enterPinVC.completionHandler = completionHandler
        vc.present(enterPinVC, animated: true) {
            
        }
    }
}
