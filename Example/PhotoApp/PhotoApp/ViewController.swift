//
//  ViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class ViewController: UIViewController {

    /// Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
//       //  Mock
//        DispatchQueue.main.async {
//            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CheckoutViewController") as! CheckoutViewController
//            self.present(vc, animated: true, completion: nil)
//        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let typeOfSegue: String = "push"
            
        if (segue.identifier == "push") {
            let vc = segue.destination as! CheckoutViewController
            vc.typeOfSegue = typeOfSegue
        }
    }
}

