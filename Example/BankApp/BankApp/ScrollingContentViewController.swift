//
//  ScrollingContentViewController.swift
//  BankApp
//
//  Created by Adam Tierney on 10/1/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

class ScrollingContentViewController: UIViewController {

    typealias ScrollViewContentConstraints = (width: NSLayoutConstraint, height: NSLayoutConstraint)

    var scrollView: UIScrollView {
        return view as! UIScrollView
    }

    lazy private(set) var contentView: UIView = {
        let contentView = UIView(frame: .zero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        return contentView
    }()

    var minimumSize: CGSize = UIScreen.main.bounds.size {
        didSet {
            NSLayoutConstraint.deactivate([
                scrollViewContentConstraints.width,
                scrollViewContentConstraints.height,
            ])

            scrollViewContentConstraints = makeNewScrollViewContentConstraints(forSize: minimumSize)

            NSLayoutConstraint.activate([
                scrollViewContentConstraints.width,
                scrollViewContentConstraints.height,
            ])
        }
    }

    private var keyboardObserver: AnyObject?

    private var scrollViewContentConstraints: ScrollViewContentConstraints!

    override func loadView() {
        view = UIScrollView(frame: UIScreen.main.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        keyboardObserver = addKeyboardObserver()

        scrollView.addSubview(contentView)
        // NOTE: this class should default to full screen and subclasses should use the layout
        // marigns to postion content relative to safe area or pure anchors for not.
        scrollView.contentInsetAdjustmentBehavior = .never

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        // track content view constraints for updating the content view size:
        scrollViewContentConstraints = makeNewScrollViewContentConstraints(forSize: minimumSize)

        NSLayoutConstraint.activate([
            scrollView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
            scrollView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height),

            scrollViewContentConstraints.width,
            scrollViewContentConstraints.height,

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
        ])
    }
}

private extension ScrollingContentViewController {

    func addKeyboardObserver() -> AnyObject {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main) { [weak self] notification in

                guard
                    let sself = self,
                    let frameValue: NSValue = (notification as NSNotification).userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                    return
                }

                let frame = frameValue.cgRectValue
                var currentInsets = sself.scrollView.contentInset
                currentInsets.bottom = (UIScreen.main.bounds.height - frame.minY)
                self?.scrollView.contentInset = currentInsets
        }
    }

    func makeNewScrollViewContentConstraints(forSize size: CGSize) -> ScrollViewContentConstraints {
        return (
            width: contentView.widthAnchor.constraint(
                greaterThanOrEqualToConstant: size.width
            ),
            height: contentView.heightAnchor.constraint(
                greaterThanOrEqualToConstant: size.height
            )
        )
    }
}
