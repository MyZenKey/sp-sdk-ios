//
//  DividerLabel.swift
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

class DividerLabel: UIView {
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    let leftRule = UIView()

    let rightRule = UIView()

    init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        setupRule(leftRule)
        setupRule(rightRule)
        self.addSubview(label)
        self.addSubview(leftRule)
        self.addSubview(rightRule)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            label.topAnchor.constraint(equalTo: self.topAnchor),
            label.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            leftRule.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            leftRule.trailingAnchor.constraint(equalTo: label.leadingAnchor, constant: -10.0),
            leftRule.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            rightRule.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            rightRule.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 10.0),
            rightRule.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension DividerLabel {
    func setupRule(_ ruleView: UIView) {
        ruleView.translatesAutoresizingMaskIntoConstraints = false
        ruleView.backgroundColor = Color.divider
        ruleView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
    }
}
