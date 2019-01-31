//
//  SupprtProjectVerifyController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class ProjectVerifyController: UIViewController {
    @IBOutlet weak var lbl_header: UILabel!
    @IBOutlet weak var lbl_description: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationItem.setHidesBackButton(true, animated: false)
        if let text = lbl_header.text{
            let attributedString = NSMutableAttributedString(string:text)
            attributedString.addAttributes([NSAttributedStringKey.font : UIFont.init(name: "Arial-Italic", size: 30) ?? UIFont.italicSystemFont(ofSize: 30)], range: (text as NSString).range(of: "Project Verify"))
            lbl_header.attributedText = attributedString
        }
        if let text = lbl_description.text{
            let attributedString = NSMutableAttributedString(string:text)
            attributedString.addAttributes([NSAttributedStringKey.font : UIFont.init(name: "Arial-Italic", size: 18) ?? UIFont.italicSystemFont(ofSize: 18)], range: (text as NSString).range(of: "Project Verify"))
            lbl_description.attributedText = attributedString
        }
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
    @IBAction func goBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
