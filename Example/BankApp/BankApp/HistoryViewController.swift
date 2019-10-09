//
//  HistoryViewController.swift
//  BankApp
//
//  Created by Chad on 9/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

final class HistoryViewController: UITableViewController {

    fileprivate static let transactionHistoryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy - h:mm a"
        return formatter
    }()

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
        tableView.separatorInset = UIEdgeInsets(
            top: 0,
            left: Constants.largeSpacer,
            bottom: 0,
            right: Constants.largeSpacer
        )

        // hide extra cell separators
        tableView.tableFooterView = UIView()

        NSLayoutConstraint.activate([
            demoPurposes.leadingAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.leadingAnchor),
            demoPurposes.trailingAnchor.constraint(equalTo: backgroundView.layoutMarginsGuide.trailingAnchor),
            demoPurposes.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.smallSpacer),
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Add an additional inset for the demo purposes label's height. The demo lable is pinned
        // to the safe area bottom and the table's content is inset as much by default. Add the
        // label's height + padding to have it show when you scroll to the bottom:
        tableView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: demoPurposes.frame.height + (2 * Constants.smallSpacer),
            right: 0
        )
    }
}

private extension HistoryViewController {

    enum Constants {
        static let largeSpacer: CGFloat = 25
        static let mediumSpacer: CGFloat = 15
        static let smallSpacer: CGFloat = 8
    }

    func syncTransactions() {
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
        margins.left = Constants.largeSpacer
        margins.right = Constants.largeSpacer
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

        let transaction = transactions[indexPath.row]
        cell.circleText = "JD"
        cell.titleText = "John Doe"
        cell.subtitleText = "#\(transaction.id)"
        cell.footerText = HistoryViewController.transactionHistoryDateFormatter.string(
            from: transaction.time
        )
        cell.accessoryText = transaction.amount

        return cell
    }
}
