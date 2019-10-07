//
//  HistoryViewController.swift
//  BankApp
//
//  Created by Chad on 9/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

final class HistoryViewController: UITableViewController {

    private var transactions = [Transaction]()

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    private(set) lazy var demoPurposes = UIViewController.makeDemoPurposesLabel()

    private(set) lazy var backgroundView: UIView = {
        let backgroundView = UIView(frame: .zero)
        backgroundView.addSubview(demoPurposes)
        return backgroundView
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Transfer Log"

        updateMargins()

        tableView.backgroundColor = Colors.white.value
        tableView.backgroundView = backgroundView
        tableView.register(
            TransactionTableCell.self,
            forCellReuseIdentifier: TransactionTableCell.identifier
        )

        tableView.dataSource = self

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Colors.primaryText.value
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 25.0, bottom: 0, right: 25.0)

        // hide extra cell separators
        tableView.tableFooterView = UIView()

        NSLayoutConstraint.activate([
            demoPurposes.leadingAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.leadingAnchor),
            demoPurposes.trailingAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.trailingAnchor),
            demoPurposes.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        syncTransactions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let safeAreaInset = view.safeAreaInsets.bottom
        tableView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: safeAreaInset + 28.0,
            right: 0
        )
    }
}

private extension HistoryViewController {
    func syncTransactions() {
        // fetch data
        serviceAPI.getTransactions() { [weak self] transactions,_ in
            guard let newTransactions = transactions else {
                return
            }
            self?.updateTransactions(newTransactions)
        }
    }

    func updateTransactions(_ newTransactions: [Transaction]) {
        transactions = newTransactions
        tableView.reloadData()
    }

    func updateMargins() {
        var margins = tableView.layoutMargins
        margins.left = 25.0
        margins.right = 25.0
        margins.bottom = 0
        tableView.layoutMargins = margins
    }
}

// MARK: - UITableViewDelegate
extension HistoryViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableCell.identifier) as? TransactionTableCell else {
            fatalError("TransactionTableCell cell unavailable, check table configuration")
        }

//        let transaction = transactions[indexPath.row]
        cell.circleText = "JD"
        cell.titleText = "Sent some money"
        cell.subtitleText = "99999999"
        cell.footerText = "Sept 1, 2019 - 5:55 PM"
        cell.accessoryText = "$100"

        return cell
    }
}
