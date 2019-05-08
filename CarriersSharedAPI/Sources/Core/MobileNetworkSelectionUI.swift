//
//  MobileNetworkSelectionUI.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 5/7/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import Foundation

protocol MobileNetworkSelectionUIProtocol {
    func showMobileNetworkSelectionUI(
        fromController viewController: UIViewController,
        usingURL url: URL,
        onUIDidCancel: @escaping () -> Void
    )

    func close(completion: @escaping () -> Void)
}
