//
//  SupprtProjectVerifyController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class ProjectVerifyController: UIViewController {
    let titleViewImage: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.contentMode = .scaleAspectFit
        img.image = UIImage(named: "icon_Socialapp_inverse")
        return img
    }()
    
    let headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "We now support Project Verify"
        label.font = UIFont.boldSystemFont(ofSize: 36)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Would you like to use Project Verify to sign in to Socialapp?"
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let yesButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        button.backgroundColor = AppTheme.themeColor
        button.setTitle("YES", for: .normal)
        return button
    }()
    
    let noButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("No thanks", for: .normal)
        button.setTitleColor(AppTheme.themeColor, for: .normal)
        return button
    }()
    
    let illustrationPurposes: UILabel = BuildInfo.makeWatermarkLabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        layoutView()
    }
    
    func goBack(sender: Any){
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func layoutView() {
        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = view.safeAreaLayoutGuide
        
        navigationItem.titleView = titleViewImage
        navigationController?.isNavigationBarHidden =  false
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton = true
        
        if let text = headerLabel.text{
            let attributedString = NSMutableAttributedString(string:text)
            attributedString.addAttributes([NSAttributedStringKey.font : UIFont(name: "SFCompactText-Italic", size: 30) ?? UIFont.systemFont(ofSize: 30)], range: (text as NSString).range(of: "Project Verify"))
            headerLabel.attributedText = attributedString
        }
        
        if let text = descriptionLabel.text{
            let attributedString = NSMutableAttributedString(string:text)
            attributedString.addAttributes([NSAttributedStringKey.font : UIFont(name: "SFCompactText-Italic", size: 18) ?? UIFont.systemFont(ofSize: 18)], range: (text as NSString).range(of: "Project Verify"))
            descriptionLabel.attributedText = attributedString
        }
        
        view.addSubview(headerLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(noButton)
        view.addSubview(yesButton)
        view.addSubview(illustrationPurposes)
        
        constraints.append(headerLabel.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 80))
        constraints.append(headerLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 20))
        constraints.append(headerLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -20))
        
        constraints.append(descriptionLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 30))
        constraints.append(descriptionLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 20))
        constraints.append(descriptionLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -20))
        
        constraints.append(noButton.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor, constant: -30))
        constraints.append(noButton.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        
        constraints.append(yesButton.bottomAnchor.constraint(equalTo: noButton.topAnchor, constant: -40))
        constraints.append(yesButton.centerXAnchor.constraint(equalTo: safeAreaGuide.centerXAnchor))
        constraints.append(yesButton.heightAnchor.constraint(equalToConstant: 44))
        constraints.append(yesButton.widthAnchor.constraint(equalToConstant: 100))
        
        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))
        
        NSLayoutConstraint.activate(constraints)
    }
    
}
