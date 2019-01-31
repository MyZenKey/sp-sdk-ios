//
//  extension.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import Foundation
import UIKit
import CoreGraphics

extension UITextField {
    func setBottomBorder(color:UIColor) {
        let border = CALayer();
        let width = CGFloat(2.0);
         border.borderColor = color.cgColor;
      
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width:  self.frame.size.width, height: 10.0);
        border.borderWidth = width;
        
        self.layer.addSublayer(border);
        self.layer.masksToBounds = true;
    }
    

}

extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{3,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    
    func isValidZipCode() -> Bool {
        let zipCodeRegex = "^[0-9]{5}(-[0-9]{4})?$" ;
        return NSPredicate(format: "SELF MATCHES %@", zipCodeRegex).evaluate(with: self)
        
    }
    
    mutating func deleteLastChar() {
        if count > 0 {
            remove(at: index(before: endIndex))
        }
    }
    
    var withoutSpecialCharacters: String {
        return self.components(separatedBy: CharacterSet.symbols).joined(separator: "  ")
    }
}

extension UIColor {
    
    convenience init(hexString: String) {
        let hexStringCleaned = hexString.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
        var hexIntValue: UInt32 = 0
        let scanner = Scanner(string: hexStringCleaned)
        scanner.scanHexInt32(&hexIntValue)
        let a, r, g, b: UInt32
        switch hexStringCleaned.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (hexIntValue >> 8) * 17, (hexIntValue >> 4 & 0xF) * 17, (hexIntValue & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, hexIntValue >> 16, hexIntValue >> 8 & 0xFF, hexIntValue & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (hexIntValue >> 24, hexIntValue >> 16 & 0xFF, hexIntValue >> 8 & 0xFF, hexIntValue & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

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

extension UIView {
    func showActivityIndicator()  {
        
        let backgroundView = UIView()
        backgroundView.frame = CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height);
        backgroundView.backgroundColor = UIColor.clear;
        backgroundView.tag = 100;
        
       
        let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView();
        activityIndicator.frame = CGRect(x: 0.0, y: 0.0, width: 50, height: 50);
        activityIndicator.center = self.center;
        activityIndicator.activityIndicatorViewStyle = .gray;
        activityIndicator.startAnimating();
        backgroundView.addSubview(activityIndicator);
        self.addSubview(backgroundView)
            
    }
    func hideActivityIndicator()  {
        if let activityIndicator = self.viewWithTag(100){
            activityIndicator.removeFromSuperview();
        }
    }
}
