//
//  ViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var okButton: UIButton!
    @IBOutlet var navigationBar: UINavigationBar!
    var  statusBarDefaultColor :UIColor!;
    /// Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad();
       
        /*let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        statusBarDefaultColor = statusBar.backgroundColor;
        if statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
           
            statusBar.backgroundColor = UIColor( red: CGFloat(191/255.0), green: CGFloat(25/255.0), blue: CGFloat(32/255.0), alpha: CGFloat(1.0) )
        }*/
       
        okButton.layer.cornerRadius = 20.0;

       
    }

    override func viewWillDisappear(_ animated: Bool) {
       /* let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
        
        if statusBar.responds(to:#selector(setter: UIView.backgroundColor)) {
            
            statusBar.backgroundColor = statusBarDefaultColor
        }*/
    }
    override func viewDidDisappear(_ animated: Bool) {
        
       
    }
    
    @IBAction func okButonTap(_ sender: Any) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.launchHomeScreen()
        }
    }
    
    
    
    
   
    
   
}
