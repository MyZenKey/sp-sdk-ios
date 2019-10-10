//
//  BankAppRouter.swift
//  BankApp
//
//  Created by Adam Tierney on 9/5/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

class BankAppRouter {

    private let window: UIWindow
    private var navigationController: UINavigationController = UINavigationController()

    init(window: UIWindow) {
        self.window = window
    }

    func popToRoot(animated: Bool) {
        navigationController.popToRootViewController(animated: animated)
    }

    func pop(animated: Bool) {
        navigationController.popViewController(animated: animated)
    }

    func startAppFlow() {
        let homeViewController = HomeViewController()
        navigationController = UINavigationController(rootViewController: homeViewController)
        navigationController.isNavigationBarHidden = true
        navigationController.navigationBar.tintColor = Colors.heavyText
        self.window.rootViewController = navigationController
    }

    func startLoginFlow() {
        let loginVC = LoginViewController()
        navigationController = UINavigationController(rootViewController: loginVC)
        navigationController.isNavigationBarHidden = true
        self.window.rootViewController = navigationController
    }

    func showEnableVerifyViewController(animated: Bool) {
        navigationController.pushViewController(EnableVerifyViewController(), animated: animated)
    }

    func showApproveViewController(animated: Bool) {
        navigationController.pushViewController(ApproveViewController(), animated: animated)
    }

    func showRegisterViewController(animated: Bool) {
        navigationController.pushViewController(RegisterViewController(), animated: animated)
    }

    func showTransfersScreen(animated: Bool) {
        navigationController.setViewControllers([
            HomeViewController(),
            TransfersViewController(),
        ], animated: animated)
    }

    func showHistoryScreen(animated: Bool) {
        navigationController.setViewControllers([
            HomeViewController(),
            HistoryViewController(),
            ], animated: animated)
    }
}
