//
//  StyledTextField.swift
//  ZenKeySDK
//
//  Created by Kyle Alan Hale on 4/1/20.
//  Copyright © 2020 ZenKey, LLC.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UIKit

class StyledTextField: UITextField {
    let cornerRadius: CGFloat = 3.0
    let borderColor = Color.inputBorder
    let paddingInsets = UIEdgeInsets(top: 14.0, left: 12.0, bottom: 14.0, right: 12.0)

    init() {
        super.init(frame: .zero)
        self.layer.borderWidth = 1.0
        // borderColor is set in layoutSubviews
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
        self.textColor = Color.Text.main
        self.minimumFontSize = 17.0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override var placeholder: String? {
        didSet {
            guard let placeholder = placeholder else { return }
            let placeholderColor = Color.Text.buttonDisabled
            self.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: placeholderColor])
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: paddingInsets)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: paddingInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: paddingInsets)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Assign cgColors in case trait collection changes
        self.layer.borderColor = borderColor.cgColor
    }
}
