//
//  ProjectVerifyAuthorizeButton.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/3/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

public protocol ProjectVerifyAuthorizeButtonDelegate: AnyObject {
    
    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton)
    
    func buttonDidFinish(
        _ button: ProjectVerifyAuthorizeButton,
        withResult result: AuthorizationResult)
}

public final class ProjectVerifyAuthorizeButton: ProjectVerifyBrandedButton {

    public var scopes: [ScopeProtocol] = []
    
    public weak var delegate: ProjectVerifyAuthorizeButtonDelegate?
    
    fileprivate let authorizationService: AuthorizationService = AuthorizationService()
    
    fileprivate var requestState: RequestState = .idle
    
    public override init() {
        super.init()
        configureSelectors()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureSelectors()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureSelectors()
    }
    
    @objc func handlePress(sender: Any) {
        guard requestState == .idle else {
            return
        }
        
        guard let currentViewController = UIViewController.currentController else {
            fatalError("attempting to authroize before the key window has a root view controller")
        }
        
        delegate?.buttonWillBeginAuthorizing(self)
        
        requestState = .authorizing
        
        authorizationService.connectWithProjectVerify(
            scopes: scopes,
            fromViewController: currentViewController) { [weak self] result in
                self?.handle(result: result)
        }
    }
}

private extension ProjectVerifyAuthorizeButton {
    enum RequestState: Int {
        case idle, authorizing
    }

    func configureSelectors() {
        addTarget(self, action: #selector(handlePress(sender:)), for: .touchUpInside)
    }
    
    func handle(result: AuthorizationResult) {
        delegate?.buttonDidFinish(self, withResult: result)
    }
}

extension UIViewController {
    static var currentController: UIViewController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        var currentViewController: UIViewController? = rootViewController
        while let nextController = currentViewController?.presentedViewController {
            currentViewController = nextController
        }
        return currentViewController
    }
}

