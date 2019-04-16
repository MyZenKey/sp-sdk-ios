//
//  ProjectVerifyAuthorizeButton.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/3/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

/// Notifications for the ProjectVerifyAuthorizationButton authorization lifecycle
public protocol ProjectVerifyAuthorizeButtonDelegate: AnyObject {
    
    /// Called before the button starts the authorization request
    ///
    /// - Parameter button: the button implementing the request
    func buttonWillBeginAuthorizing(_ button: ProjectVerifyAuthorizeButton)
    
    
    /// Called upon request completion
    ///
    /// - Parameters:
    ///   - button: the button completing the request
    ///   - result: the result of the request
    /// - SeeAlso: `AuthorizationResult`
    func buttonDidFinish(
        _ button: ProjectVerifyAuthorizeButton,
        withResult result: AuthorizationResult)
}


/// A button which encapsulates the project verify authorization logic and exposes the outcomes
/// via a delegeate.
public final class ProjectVerifyAuthorizeButton: ProjectVerifyBrandedButton {

    /// The scopes the button will request when pressed. Assign this property before the button
    /// issues its request.
    public var scopes: [ScopeProtocol] = []
    
    /// the button's delegate
    /// @SeeAlso: ProjectVerifyAuthorizeButtonDelegate
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
