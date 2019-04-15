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

    fileprivate(set) var requestState: RequestState = .idle

    fileprivate private(set) var authorizationService: AuthorizationServiceProtocol = AuthorizationService()
    fileprivate private(set) var controllerContextProvider: CurrentControllerContextProvider = DefaultCurrentControllerContextProvider()
    
    public override init() {
        super.init()
        configureSelectors()
    }
    
    init(authorizationService: AuthorizationServiceProtocol,
         controllerContextProvider: CurrentControllerContextProvider) {
        self.authorizationService = authorizationService
        self.controllerContextProvider = controllerContextProvider
        
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
        
        guard let currentViewController = controllerContextProvider.currentController else {
            fatalError("attempting to authorize before the key window has a root view controller")
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

extension ProjectVerifyAuthorizeButton {
    enum RequestState: Int {
        case idle, authorizing
    }
}

private extension ProjectVerifyAuthorizeButton {
    func configureSelectors() {
        addTarget(self, action: #selector(handlePress(sender:)), for: .touchUpInside)
    }
    
    func handle(result: AuthorizationResult) {
        requestState = .idle
        delegate?.buttonDidFinish(self, withResult: result)
    }
}
