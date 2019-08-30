//
//  ImageUtils.swift
//  ZenKeySDK
//
//  Created by Adam Tierney on 4/10/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

class ImageUtils {
    static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: Bundle(for: ImageUtils.self), compatibleWith: nil)
    }
}
