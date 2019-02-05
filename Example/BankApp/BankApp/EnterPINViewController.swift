//
//  EnterPINViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class EnterPINViewController: UIViewController {
    
    let logo: UIImageView = {
        let logo = UIImageView()
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.image = UIImage(named: "logosmall")
        logo.contentMode = .scaleAspectFit
        return logo
    }()
    
    let enterPinLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Enter Pin"
        label.font = UIFont.systemFont(ofSize: 24)
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        return label
    }()
    
    let confirmLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Unlock to confirm"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        return label
    }()
    
    let dotStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 25
        stack.contentMode = .scaleAspectFit
        return stack
    }()
    
    let backButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("< Back", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(AppTheme.primaryBlue, for: .normal)
        button.addTarget(self, action: #selector(backButtonTouched(_:)), for: .touchUpInside)
        return button
    }()
    
    // The six dots
    let dotView0 = DotView()
    let dotView1 = DotView()
    let dotView2 = DotView()
    let dotView3 = DotView()
    let dotView4 = DotView()
    let dotView5 = DotView()
    
    fileprivate var dotViews: [DotView] = []
    fileprivate var numDigits = 0
    fileprivate var completionHandler: ((Bool)->Void)?
    
    // This is the receiver for user input
    fileprivate var hiddenInputTextField: UITextField!
    
    fileprivate var enteredPIN: String = ""
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowHide(_:)), name: .UIKeyboardWillShow, object: nil)
        
        layoutView()
        setupInputField()
        setupDots()
        applyAppTheme()
    }
    
    @objc func keyboardWillShowHide(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {

            // Animate the "< Back" button up or down based on whether keyboard was shown or hidden.
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
//            backButtonBottomContraint.constant = keyboardHeight + 34
            self.backButton.frame.origin.y -= keyboardHeight + 34
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
    
    @objc func backButtonTouched(_ sender: Any) {
        completionHandler?(false)
        navigationController?.popViewController(animated: true)
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        
        view.addSubview(logo)
        view.addSubview(enterPinLabel)
        view.addSubview(confirmLabel)
        view.addSubview(dotStack)
        view.addSubview(backButton)
        
        constraints.append(NSLayoutConstraint(item: logo,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .top,
                                              multiplier: 1,
                                              constant: 20))
        constraints.append(NSLayoutConstraint(item: logo,
                                              attribute: .centerX,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .centerX,
                                              multiplier: 1,
                                              constant: 0))
        constraints.append(logo.heightAnchor.constraint(equalToConstant: 46))
        constraints.append(logo.widthAnchor.constraint(equalToConstant: 46))
        
        constraints.append(NSLayoutConstraint(item: enterPinLabel,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: logo,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 20))
        constraints.append(NSLayoutConstraint(item: enterPinLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: enterPinLabel,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        
        constraints.append(NSLayoutConstraint(item: confirmLabel,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: enterPinLabel,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 10))
        constraints.append(NSLayoutConstraint(item: confirmLabel,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: confirmLabel,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        
        
        constraints.append(NSLayoutConstraint(item: dotStack,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: confirmLabel,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: 50))
        constraints.append(NSLayoutConstraint(item: dotStack,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 30))
        constraints.append(NSLayoutConstraint(item: dotStack,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: -30))
        constraints.append(dotStack.heightAnchor.constraint(equalToConstant: 30))
        
        constraints.append(NSLayoutConstraint(item: backButton,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .bottom,
                                              multiplier: 1,
                                              constant: -10))
        constraints.append(NSLayoutConstraint(item: backButton,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: safeAreaGuide,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 20))
        
        NSLayoutConstraint.activate(constraints)
        
    }
    
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

        for dot in dotViews {
            dot.color = UIColor.lightGray
            dot.contentMode = .scaleAspectFit
            dotStack.addArrangedSubview(dot)
        }
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

//extension EnterPINViewController {
//
//    class func create() -> EnterPINViewController {
//
//        let storyboard = UIStoryboard(name:"Main", bundle: nil)
//        guard let vc = storyboard.instantiateViewController(withIdentifier: "enterPinScene") as? EnterPINViewController else {
//            fatalError("Failed to instantiate a EnterPINViewController from Main.storyboard")
//        }
//
//        return vc
//    }
//
//    class func presentPINScreen(on vc: UIViewController, completionHandler:@escaping (Bool)->Void) {
//        let enterPinVC = EnterPINViewController.create()
//        enterPinVC.completionHandler = completionHandler
//        vc.present(enterPinVC, animated: true) {
//
//        }
//    }
//}
