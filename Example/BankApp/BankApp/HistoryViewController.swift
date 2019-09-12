//
//  HistoryViewController.swift
//  BankApp
//
//  Created by Chad on 9/11/19.
//  Copyright © 2019 AT&T. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .white
        return tableView
    }()
    private var transactions: [Transaction]

    init() {
        transactions = UserAccountStorage.getTransactionHistory().reversed()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "History"
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

        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }
}

// MARK: - UITableViewDelegate

extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "TransactionCell")
        cell.translatesAutoresizingMaskIntoConstraints = false
        let transaction = transactions[indexPath.row]
        cell.textLabel?.text = "Transfered \(transaction.amount) to \(transaction.recipiant)"

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium

        let dateString = formatter.string(from: transaction.time)
        cell.detailTextLabel?.text = dateString
        cell.accessoryType = .checkmark
        return cell
    }
}
