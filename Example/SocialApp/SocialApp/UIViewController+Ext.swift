//
//  UIViewController+Ext.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import Foundation
import UIKit

extension UIViewController {
    
    func goBack() {
        if let navVC = navigationController {
            navVC.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func showOkAlert(title:String?, message: String?) {
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            
        }
        
        let alert = UIAlertController(title: title, message:message, preferredStyle: .alert);
        alert.addAction(okAction);
        present(alert, animated: true)
    }
}

