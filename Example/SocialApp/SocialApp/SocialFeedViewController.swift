//
//  SocialFeedViewController.swift
//  SocialApp
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class SocialFeedViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var tbl_feed: UITableView!
    @IBOutlet var titleViewImg: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden =  false
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
        self.navigationItem.titleView = titleViewImg
        
        tbl_feed.tableFooterView = UIView.init(frame: CGRect.zero)
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView .dequeueReusableCell(withIdentifier: "FeedCell\(indexPath.row % 2 + 1)") as? SocialFeedCell
        cell?.updateHeaderContent()
        cell?.updateDescriptionContent()

        return cell ?? UITableViewCell()
    }
}

class SocialFeedCell: UITableViewCell {
    @IBOutlet weak var lbl_header: UILabel!
    @IBOutlet weak var lbl_description: UILabel!
    var usernames = ["Chris Walton", "Rep It Up Fitness"]
    var locationname = ["Top of the Appalachian Trail"]
    var timestamp = ["just now", "July 20"]

    func updateHeaderContent(){
        if let text = lbl_header.text{
            let attributedString = NSMutableAttributedString(string:text)
            for name in usernames {
                attributedString.addAttributes([NSAttributedStringKey.font : UIFont.init(name: "SFCompactText-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14),NSAttributedStringKey.foregroundColor: UIColor.init(hexString: "#000000")], range: (text as NSString).range(of: name))
            }
            attributedString.addAttributes([NSAttributedStringKey.font : UIFont.init(name: "SFCompactText-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14),NSAttributedStringKey.foregroundColor: UIColor.init(hexString: "#000000")], range: (text as NSString).range(of: "checked in at"))
            
            for name in locationname {
                attributedString.addAttributes([NSAttributedStringKey.font : UIFont.init(name: "SFCompactText-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14),NSAttributedStringKey.foregroundColor: UIColor.init(hexString: "#007AFF")], range: (text as NSString).range(of: name))
            }
            attributedString.addAttributes([NSAttributedStringKey.font : UIFont.init(name: "SFCompactText-Regular", size: 14) ?? UIFont.systemFont(ofSize: 14),NSAttributedStringKey.foregroundColor: UIColor.init(hexString: "#000000")], range: (text as NSString).range(of: "checked in at"))

            for name in timestamp {
                attributedString.addAttributes([NSAttributedStringKey.font : UIFont.init(name: "SFCompactText-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12),NSAttributedStringKey.foregroundColor: UIColor.init(hexString: "#4A4A4A")], range: (text as NSString).range(of: name))
            }
            lbl_header.attributedText = attributedString
        }
    }
    func updateDescriptionContent(){
        if let text = lbl_description.text{
            let attributedString = NSMutableAttributedString(string:text)
            
            let hashTags = text.getHashtags() ?? []
            for hashTag in hashTags {
                attributedString.addAttributes([NSAttributedStringKey.font : UIFont.init(name: "SFCompactText-Medium", size: 14) ?? UIFont.systemFont(ofSize: 14),NSAttributedStringKey.foregroundColor: UIColor.init(hexString: "#007AFF")], range: (text as NSString).range(of: hashTag))
            }
            lbl_description.attributedText = attributedString
        }
    }
}
extension String {
    func getHashtags() -> [String]? {
        let hashtagDetector = try? NSRegularExpression(pattern: "#(\\w+)", options: NSRegularExpression.Options.caseInsensitive)
        let results = hashtagDetector?.matches(in: self, options: NSRegularExpression.MatchingOptions.withoutAnchoringBounds, range: NSMakeRange(0, self.utf16.count)).map { $0 }
       
        return results?.map({
            (self as NSString).substring(with: ($0.range(at: 0)))
        })
    }
}
