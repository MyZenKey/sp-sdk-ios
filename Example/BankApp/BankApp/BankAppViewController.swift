//
//  BankAppViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 7/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

//class BankAppViewController: UIViewController {
////
////    let gradientView: LogoGradientView = {
////        let gradientView = LogoGradientView()
////        gradientView.translatesAutoresizingMaskIntoConstraints = false
////        return gradientView
////    }()
//
//    let illustrationPurposes: UILabel = BuildInfo.makeWatermarkLabel()
//
//    var isNavigationCancelButtonHidden: Bool = true {
//        didSet {
//            navigationCancelButton.isHidden = isNavigationCancelButtonHidden
//        }
//    }
//
//    let navigationCancelButton: UIButton = {
//        let cancelButton = UIButton(type: .system)
//        cancelButton.translatesAutoresizingMaskIntoConstraints = false
//        cancelButton.setTitleColor(.white, for: .normal)
//        cancelButton.setTitle("Cancel", for: .normal)
//        cancelButton.isHidden = true
//        cancelButton.contentHorizontalAlignment = .left
//        return cancelButton
//    }()
//
//    init() {
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        view.backgroundColor = .white
//        var constraints: [NSLayoutConstraint] = []
//        let safeAreaGuide = getSafeLayoutGuide()
//
//        view.addSubview(gradientView)
//        view.addSubview(illustrationPurposes)
//        view.addSubview(navigationCancelButton)
//
//        navigationCancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
//        gradientView.addSubview(navigationCancelButton)
//
//        constraints.append(gradientView.topAnchor.constraint(equalTo: view.topAnchor))
//        constraints.append(gradientView.widthAnchor.constraint(equalTo: view.widthAnchor))
//        constraints.append(gradientView.bottomAnchor.constraint(equalTo: safeAreaGuide.topAnchor,
//                                                                constant: Constants.gradientHeaderHeight))
//        constraints.append(navigationCancelButton.leadingAnchor
//            .constraint(equalTo: gradientView.leadingButtonAreaLayoutGuide.leadingAnchor, constant: 20))
//        constraints.append(navigationCancelButton.trailingAnchor
//            .constraint(equalTo: gradientView.leadingButtonAreaLayoutGuide.trailingAnchor, constant: 20))
//        constraints.append(navigationCancelButton.topAnchor
//            .constraint(equalTo: gradientView.leadingButtonAreaLayoutGuide.topAnchor))
//        constraints.append(navigationCancelButton.bottomAnchor
//            .constraint(equalTo: gradientView.leadingButtonAreaLayoutGuide.bottomAnchor))
//
//        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
//        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
//        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))
//
//        NSLayoutConstraint.activate(constraints)
//    }
//
//    @objc func cancel() {
//        sharedRouter.pop(animated: true)
//    }
//}
