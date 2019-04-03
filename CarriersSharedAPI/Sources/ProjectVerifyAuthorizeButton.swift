//
//  ProjectVerifyAuthorizeButton.swift
//  CarriersSharedAPI
//
//  Created by Adam Tierney on 4/3/19.
//  Copyright © 2019 XCI JV, LLC. All rights reserved.
//

import UIKit

public class ProjectVerifyBrandedButton: UIButton {
    
    var branding: Branding = .default {
        didSet {
            updateBranding()
        }
    }
    
    let configCacheService: ConfigCacheServiceProtocol = ProjectVerifyBrandedButton
        .resolveConfigCacheService()
    
    let carrierInfoService: CarrierInfoServiceProtocol = ProjectVerifyBrandedButton
        .resolveCarrierInfoService()
    
    public init() {
        super.init(frame: .zero)
        configureButton()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureButton()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureButton()
    }
    
    private func configureButton() {
        branding = brandingFromCache()
        updateBranding()
    }
    
    private func updateBranding() {
        
    }
}

extension ProjectVerifyBrandedButton {
    enum Branding {
        case `default`
    }
    
    func brandingFromCache() -> Branding {
        guard
            let primarySIM = carrierInfoService.primarySIM,
            let config = configCacheService.config(
                forSIMInfo: primarySIM,
                allowStaleRecords: true) else {
                    return .default
        }
        
        guard let branding = config.branding else {
            return .default
        }
        
        return branding
    }
}

extension OpenIdConfig {
    var branding: ProjectVerifyBrandedButton.Branding {
        return .default
    }
}

private extension ProjectVerifyBrandedButton {
    static func resolveCarrierInfoService() -> CarrierInfoServiceProtocol {
        return ProjectVerifyAppDelegate
            .shared
            .dependencies
            .carrierInfoService
    }

    static func resolveConfigCacheService() -> ConfigCacheServiceProtocol {
        return ProjectVerifyAppDelegate
            .shared
            .dependencies
            .configCacheService
    }
}

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

private extension CGSize {
    static var projectVerifyButtonSize: CGSize {
        return CGSize(width: 320, height: 40)
    }
}
