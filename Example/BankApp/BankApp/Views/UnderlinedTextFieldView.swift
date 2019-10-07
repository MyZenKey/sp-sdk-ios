//
//  UnderlinedTextFieldView.swift
//  BankApp
//
//  Created by Adam Tierney on 9/30/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

class UnderlinedTextFieldView: UIView {
    override class var requiresConstraintBasedLayout: Bool {
        return true
    }

    var textFieldDelegate: UITextFieldDelegate? {
        get { return field.delegate }
        set { field.delegate = newValue }
    }

    var text: String? {
        get { return field.text }
        set { field.text = newValue }
    }

    var placeholder: String? {
        get { return field.placeholder }
        set {
            guard let newValue = newValue else {
                field.attributedPlaceholder = nil
                return
            }
            
            field.attributedPlaceholder = NSAttributedString(
                string: newValue,
                attributes: Constants.placeholderAttributes
            )
        }
    }

    var isSecureTextEntry: Bool {
        get { return field.isSecureTextEntry }
        set { field.isSecureTextEntry = newValue }
    }

    private let field: UITextField = {
        let field = UITextField(frame: .zero)
        field.translatesAutoresizingMaskIntoConstraints = false
        var attributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.textField,
            .foregroundColor: Colors.heavyText.value,
            .kern: 0.2,
        ]
        field.defaultTextAttributes = attributes
        return field
    }()

    private let hairline: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    convenience init() {
        self.init(frame: .zero)
        sharedInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("unavailable")
    }

    @objc func updateState() {
        if field.isEditing {
            hairline.backgroundColor = Colors.brightAccent.value
        } else {
            hairline.backgroundColor = Colors.lightAccent.value
        }
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return field.resignFirstResponder()
    }


    override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard !isHidden else { return .zero }

        return CGSize(
            width: size.width,
            height: max(size.height, Constants.intrinsicHeight)
        )
    }

    override var intrinsicContentSize: CGSize {
        return sizeThatFits(.zero)
    }
}

private extension UnderlinedTextFieldView {
    func sharedInit() {

        backgroundColor = Colors.fieldBackground.value

        translatesAutoresizingMaskIntoConstraints = false

        setupViews()

        field.addTarget(self, action: #selector(updateState), for: .editingDidBegin)
        field.addTarget(self, action: #selector(updateState), for: .editingDidEnd)

        updateState()
    }

    func setupViews() {
        addSubview(field)
        addSubview(hairline)

        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: topAnchor),
            field.bottomAnchor.constraint(equalTo: bottomAnchor),
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalInset),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalInset),

            hairline.bottomAnchor.constraint(equalTo: bottomAnchor),
            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: Constants.hairlineHeight)
        ])
    }

    enum Constants {
        static let intrinsicHeight: CGFloat = 40
        static let horizontalInset: CGFloat = 7
        static let hairlineHeight: CGFloat = 2
        static let textAttributes: [NSAttributedString.Key: Any] = [
            .font: Fonts.textField,
            .foregroundColor: Colors.heavyText.value,
            .kern: 0.2,
        ]
        static let placeholderAttributes: [NSAttributedString.Key: Any] = {
            var attributes = Constants.textAttributes
            attributes[.foregroundColor] = Colors.primaryText.value
            return attributes
        }()
    }
}
