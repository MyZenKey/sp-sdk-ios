//
//  CurrentControllerContextProvider.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/12/19.
//  Copyright © 2019 XCI JV, LLC.
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

import UIKit

protocol CurrentControllerContextProvider {
    var currentController: UIViewController? { get }
}

class DefaultCurrentControllerContextProvider: CurrentControllerContextProvider {
    var currentController: UIViewController? {
        return UIViewController.currentController
    }
}

extension UIViewController {
    static var currentController: UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        guard let rootViewController = keyWindow?.rootViewController else {
            return nil
        }
        var currentViewController: UIViewController? = rootViewController
        while let nextController = currentViewController?.presentedViewController {
            currentViewController = nextController
        }
        return currentViewController
    }
}
