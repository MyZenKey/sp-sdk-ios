//
//  DebugViewController.swift
//  BankApp
//
//  Created by Chad on 9/18/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

class DebugViewController: UIViewController {

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        return tableView
    }()

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
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(hide))
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

    func makeBackendPicker() -> UIAlertController {
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
        return controller
    }

    func makeEnvironmentPicker() -> UIAlertController {
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
        return controller
    }

    func makeAuthModePicker() -> UIAlertController {
        let controller = UIAlertController(
            title: "Set Login Auth Mode",
            message: nil,
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(
            title: "1 Factor (aal1)",
            style: .default,
            handler: { [weak self] _ in
                BuildInfo.setAuthMode(.aal1)
                self?.tableView.reloadData()
            }
        ))
        controller.addAction(UIAlertAction(
            title: "2 Factor after 30 minutes (aal2)",
            style: .default,
            handler: { [weak self] _ in
                BuildInfo.setAuthMode(.aal2)
                self?.tableView.reloadData()
            }
        ))
        controller.addAction(UIAlertAction(
            title: "2 Factor each time (aal3)",
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
        return controller
    }
}

// MARK: - UITableViewDelegate
extension DebugViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // handle debug options
        var alertController: UIAlertController?
        switch indexPath.row {
        case 0:
            alertController = makeBackendPicker()
        case 1:
            alertController = makeEnvironmentPicker()
        case 2:
            alertController = makeAuthModePicker()
        default:
            break
        }
        guard let controller = alertController else {return}
        present(controller, animated: true, completion: nil)
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
            cell.textLabel?.text = "Login Auth mode:"
            switch BuildInfo.currentAuthMode {
            case .aal1:
                cell.detailTextLabel?.text = "1 Factor (aal1)"
            case .aal2:
                cell.detailTextLabel?.text = "2 Factor after 30 minutes (aal2)"
            case .aal3:
                cell.detailTextLabel?.text = "2 Factor each time (aal3)"
            }
        default:
            break
        }
        return cell
    }
}
