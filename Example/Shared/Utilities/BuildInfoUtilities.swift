//
//  BuildInfoUtilities.swift
//  Example Apps
//
//  Created by Adam Tierney on 7/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import Foundation
import ZenKeySDK

struct BuildInfo {

    private static let hostToggleKey = "qaHost"
    private static let mockDemoServiceKey = "bankAppMockServiceKey"
    private static let authModeKey = "authModeKey"

    static var isQAHost: Bool {
        return UserDefaults.standard.value(forKey: hostToggleKey) != nil
    }

    static func toggleHost() {
        guard !isQAHost else  {
            UserDefaults.standard.set(nil, forKey: hostToggleKey)
            return
        }
        UserDefaults.standard.set(true, forKey: hostToggleKey)
    }

    static var isMockDemoService: Bool {
        return UserDefaults.standard.value(forKey: mockDemoServiceKey) != nil
    }

    static func toggleMockDemoService() {
        guard !isMockDemoService else  {
            UserDefaults.standard.set(nil, forKey: mockDemoServiceKey)
            return
        }
        UserDefaults.standard.set(true, forKey: mockDemoServiceKey)
    }

    static var currentAuthMode: ACRValue {
        let authString = UserDefaults.standard.string(forKey: authModeKey)
        if let authStringUnwrapped = authString {
            return ACRValue(rawValue: authStringUnwrapped) ?? .aal1
        } else {
            return .aal1
        }
    }

    static func setAuthMode(_ newMode: ACRValue) {
        UserDefaults.standard.set(newMode.rawValue, forKey: authModeKey)
    }

    static var zenKeyOptions: ZenKeyOptions {
        var options: ZenKeyOptions = [:]
        if isQAHost {
            options[.qaHost] = true
        }
        if let mockCarrier = ProcessInfo.processInfo.environment["ZENKEY_MOCK_CARRIER"],
            let value = Carrier(rawValue: mockCarrier) {
            options[.mockedCarrier] = value
        }
        options[.logLevel] = Log.Level.info
        return options
    }

    static func makeWatermarkLabel(lightText: Bool = false) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false

        let illustrationText = "For illustration purposes only"
        let serverText: String? = isQAHost ? "Connected to QA Server" : nil
        let demoAppServiceText: String? = isMockDemoService ? "Mocking Demo App Service" : nil
        label.text = [illustrationText, serverText, demoAppServiceText]
            .compactMap() { $0 }
            .joined(separator: "\n")
        label.textAlignment = .center
        label.numberOfLines = 0
        if lightText {
            label.textColor = .white
        }
        return label
    }

    static func serviceProviderAPI() -> ServiceProviderAPIProtocol {
        if isMockDemoService {
            return MockAuthService()
        } else {
            return ClientSideServiceAPI()
        }
    }
}

class DebugViewController: UIViewController {

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        return tableView
    }()
    private var transactions = [Transaction]()
    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    static func addMenu(toView view: UIView) {
        let debugGesture = UITapGestureRecognizer(target: self, action: #selector(show))
        debugGesture.numberOfTapsRequired = 3
        debugGesture.numberOfTouchesRequired = 2
        view.addGestureRecognizer(debugGesture)
    }

    static func addMenu(toViewController viewController: UIViewController) {
        addMenu(toView: viewController.view)
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Debug Menu"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(hide))
        // Table
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let safeAreaGuide = getSafeLayoutGuide()
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor),
            ])
        tableView.dataSource = self
        tableView.delegate = self

        tableView.reloadData()
    }

}

private extension DebugViewController {

    @objc func hide() {
        navigationController?.dismiss(animated: true, completion: {})
    }

    @objc static func show() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate,
            let rootViewController = delegate.window?.rootViewController else {
                return
        }

        var topMostViewController: UIViewController? = rootViewController
        while topMostViewController?.presentedViewController != nil {
            topMostViewController = topMostViewController?.presentedViewController!
        }

        let controller = DebugViewController()
        let navController = UINavigationController(rootViewController: controller)
        topMostViewController?.present(navController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate

extension DebugViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // handle debug options
        switch indexPath.row {
        case 0:
            let controller = UIAlertController(
                title: "Set Backend",
                message: "Requires reset",
                preferredStyle: .alert
            )
            controller.addAction(UIAlertAction(
                title: "Mock All Success",
                style: .destructive,
                handler: { _ in
                    if BuildInfo.isMockDemoService == false {
                        BuildInfo.toggleMockDemoService()
                        fatalError("restarting app")
                    }
                }
            ))
            controller.addAction(UIAlertAction(
                title: "Make Requests From Client App",
                style: .destructive,
                handler: { _ in
                    if BuildInfo.isMockDemoService {
                        BuildInfo.toggleMockDemoService()
                        fatalError("restarting app")
                    }
                }
            ))
            controller.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            ))
            present(controller, animated: true, completion: nil)
        case 1:
            let controller = UIAlertController(
                title: "Set JV Host Environment",
                message: "Requires reset",
                preferredStyle: .alert
            )
            controller.addAction(UIAlertAction(
                title: "QA",
                style: .destructive,
                handler: { _ in
                    if BuildInfo.isQAHost == false {
                        BuildInfo.toggleHost()
                        fatalError("restarting app")
                    }
            }
            ))
            controller.addAction(UIAlertAction(
                title: "Production",
                style: .destructive,
                handler: { _ in
                    if BuildInfo.isQAHost {
                        BuildInfo.toggleHost()
                        fatalError("restarting app")
                    }
            }
            ))
            controller.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            ))
            present(controller, animated: true, completion: nil)
        case 2:
            let controller = UIAlertController(
                title: "Set Auth Mode",
                message: nil,
                preferredStyle: .alert
            )
            controller.addAction(UIAlertAction(
                title: "AAL1: 1 Factor",
                style: .default,
                handler: { [weak self] _ in
                    BuildInfo.setAuthMode(.aal1)
                    self?.tableView.reloadData()
            }
            ))
            controller.addAction(UIAlertAction(
                title: "AAL2: 2 Factor, 30 minute",
                style: .default,
                handler: { [weak self] _ in
                    BuildInfo.setAuthMode(.aal2)
                    self?.tableView.reloadData()
            }
            ))
            controller.addAction(UIAlertAction(
                title: "AAL3: 2 Factor, every time",
                style: .default,
                handler: { [weak self] _ in
                    BuildInfo.setAuthMode(.aal3)
                    self?.tableView.reloadData()
            }
            ))
            controller.addAction(UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            ))
            present(controller, animated: true, completion: nil)
        default:
            break
        }
    }
}

extension DebugViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "DebugCell")
        cell.translatesAutoresizingMaskIntoConstraints = false

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Application Backend:"
            if BuildInfo.isMockDemoService {
                cell.detailTextLabel?.text = "Mock All Success"
            } else {
                cell.detailTextLabel?.text = "Make Requests From Client App"
            }
        case 1:
            cell.textLabel?.text = "JV Host Environment:"
            if BuildInfo.isQAHost {
                cell.detailTextLabel?.text = "QA"
            } else {
                cell.detailTextLabel?.text = "Production"
            }
        case 2:
            cell.textLabel?.text = "Auth mode:"
            switch BuildInfo.currentAuthMode {
            case .aal1:
                cell.detailTextLabel?.text = "AAL1: 1 Factor"
            case .aal2:
                cell.detailTextLabel?.text = "AAL2: 2 Factor, 30 minute"
            case .aal3:
                cell.detailTextLabel?.text = "AAL3: 2 Factor, every time"
            }
        default:
            break
        }
        return cell
    }
}
