//
//  BankAppViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 7/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

class BankAppViewController: UIViewController {

    let gradientView: LogoGradientView = {
        let gradientView = LogoGradientView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        return gradientView
    }()

    let illustrationPurposes: UILabel = BuildInfo.makeWatermarkLabel()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        var constraints: [NSLayoutConstraint] = []
        let safeAreaGuide = getSafeLayoutGuide()

        view.addSubview(gradientView)
        view.addSubview(illustrationPurposes)

        constraints.append(gradientView.topAnchor.constraint(equalTo: view.topAnchor))
        constraints.append(gradientView.widthAnchor.constraint(equalTo: view.widthAnchor))
        constraints.append(gradientView.bottomAnchor.constraint(equalTo: safeAreaGuide.topAnchor,
                                                                constant: Constants.gradientHeaderHeight))

        constraints.append(illustrationPurposes.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor))
        constraints.append(illustrationPurposes.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor))
        constraints.append(illustrationPurposes.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor))

        NSLayoutConstraint.activate(constraints)
    }
}
