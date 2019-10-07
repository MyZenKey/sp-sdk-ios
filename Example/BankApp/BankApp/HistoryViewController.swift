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

final class TransactionTableCell: UITableViewCell {

    static let identifier = "TransactionTableCell"

    var circleText: String = "" {
        didSet {
            circleLabel.attributedText = Fonts.boldHeadlineText(
                text: circleText,
                withColor: Colors.white.value
            )
        }
    }

    var titleText: String = "" {
        didSet {
            titleLabel.attributedText = Fonts.boldHeadlineText(
                text: titleText,
                withColor: Colors.heavyText.value
            )
        }
    }

    var subtitleText: String = "" {
        didSet {
            subtitleLabel.attributedText = Fonts.regularHeadlineText(
                text: subtitleText,
                withColor: Colors.primaryText.value
            )
        }
    }

    var footerText: String = "" {
        didSet {
            footerLabel.attributedText = Fonts.accessoryText(
                text: footerText,
                withColor: Colors.primaryText.value
            )
        }
    }

    var accessoryText: String = "" {
        didSet {
            accessoryLabel.attributedText = Fonts.boldHeadlineText(
                text: accessoryText,
                withColor: Colors.heavyText.value
            )
        }
    }

    private let circleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return label
    }()

    private lazy var circleView: CircleView = {
        let view = CircleView(frame: .zero)

        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Colors.brightAccent.value
        view.addSubview(circleLabel)

        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 40),
            circleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            circleLabel.topAnchor.constraint(equalTo: view.topAnchor),
            circleLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            circleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            circleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()

    private let footerLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        return label
    }()

    private let accessoryLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        return label
    }()

    private(set) lazy var labelStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel,
            footerLabel,
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 2

        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            circleView,
            labelStack,
            accessoryLabel,
        ])

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 25

        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TransactionTableCell {
    func sharedInit() {
        contentView.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }
}

private final class CircleView: UIView {

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func sharedInit() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: heightAnchor),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = ceil(frame.height / 2)
    }
}
