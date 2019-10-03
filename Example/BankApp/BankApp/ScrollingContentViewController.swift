//
//  ScrollingContentViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 10/1/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

class ScrollingContentViewController: UIViewController {

    var scrollView: UIScrollView {
        return view as! UIScrollView
    }

    lazy private(set) var contentView: UIView = {
        let contentView = UIView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()

    private var token: ObservationToken?

    override func loadView() {
        view = UIScrollView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        token = startAvoidingKeyboard(additionalAnimations: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        token = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.addSubview(contentView)

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(
                greaterThanOrEqualTo: view.safeAreaLayoutGuide.widthAnchor
            ),
            contentView.heightAnchor.constraint(
                greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor
            ),

            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}

extension ScrollingContentViewController: KeyboardAvoiding { }


