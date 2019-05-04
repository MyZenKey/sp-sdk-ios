//
//  ImageUtils.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/10/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

class ImageUtils {
    static func image(named: String) -> UIImage? {
        return UIImage(named: named, in: Bundle(for: ImageUtils.self), compatibleWith: nil)
    }
}
