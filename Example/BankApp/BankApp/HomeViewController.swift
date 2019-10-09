//
//  HomeViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class HomeViewController: UIViewController {
    let scrollView = UIScrollView()
    let contentView = UIView()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Welcome!"
        label.font = Fonts.largeTitle
        label.textColor = Colors.brightAccent.value
        return label
    }()

    let summaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Account Summary"
        label.font = Fonts.cardSection
        label.textColor = Colors.brightAccent.value
        return label
    }()

    let creditCardLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Credit Cards"
        label.font = Fonts.cardSection
        label.textColor = Colors.brightAccent.value
        return label
    }()

    let sendMoneyButton: BankAppButton = {
        let button = BankAppButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Send Money", for: .normal)
        button.addTarget(self, action: #selector(sendMoneyTouched(_:)), for: .touchUpInside)
        button.backgroundColor = Colors.brightAccent.value
        button.addBankShadow()
        return button
    }()

    let userInfoCard: UserCardView = {
        let card = UserCardView()
        return card
    }()

    let savingsCard: AccountCard = {
        let card = AccountCard("Savings", icon: UIImage(named: "pig") ?? UIImage())
        card.translatesAutoresizingMaskIntoConstraints = false

        return card
    }()

    let checkingCard: AccountCard = {
        let card = AccountCard("Preferred Checking", icon: UIImage(named: "check") ?? UIImage())
        card.translatesAutoresizingMaskIntoConstraints = false

        return card
    }()

    let creditCard: AccountCard = {
        let card = AccountCard("Premier Reserve", icon: UIImage(named: "creditCard") ?? UIImage())
        card.translatesAutoresizingMaskIntoConstraints = false

        return card
    }()

    private var userInfo: UserInfo? {
        didSet {
            updateUserInfo()
        }
    }

    private let demoPurposesLabel: UILabel = UIViewController.makeDemoPurposesLabel()

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func loadView() {
        let backgroundGradient = GradientView()
        backgroundGradient.startColor = Colors.white.value
        backgroundGradient.midColor = Colors.gradientMid.value
        backgroundGradient.endColor = Colors.gradientMax.value
        backgroundGradient.startLocation = 0.0
        backgroundGradient.midLocation = 0.45
        backgroundGradient.endLocation = 1.0
        backgroundGradient.midPointMode = true
        view = backgroundGradient
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
        title = "Home"

        // Hamburger
        let hamburgerButton = UIBarButtonItem(image: UIImage(named:"hamburger"), style: .plain, target: self, action: #selector(viewHistoryTouched(_:)))
        navigationItem.leftBarButtonItem = hamburgerButton
        // Sign Out
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(logoutButtonTouched(_:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserInfoIfNeeded()
        navigationController?.isNavigationBarHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    @objc func logoutButtonTouched(_ sender: Any) {
        (UIApplication.shared.delegate as? AppDelegate)?.logout()
    }

    @objc func viewHistoryTouched(_ sender: Any) {
        sharedRouter.showHistoryScreen(animated: true)
    }

    @objc func sendMoneyTouched(_ sender: Any) {
        sharedRouter.showApproveViewController(animated: true)
    }

    func layoutView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(userInfoCard)
        contentView.addSubview(sendMoneyButton)
        contentView.addSubview(savingsCard)
        contentView.addSubview(checkingCard)
        contentView.addSubview(creditCard)
        contentView.addSubview(summaryLabel)
        contentView.addSubview(creditCardLabel)
        contentView.addSubview(demoPurposesLabel)
        contentView.layoutMargins = UIEdgeInsets(top: 20.0, left: 25.0, bottom: 8.0, right: 25.0)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            userInfoCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            userInfoCard.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            userInfoCard.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            sendMoneyButton.topAnchor.constraint(equalTo: userInfoCard.bottomAnchor, constant: 20),
            sendMoneyButton.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            sendMoneyButton.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            sendMoneyButton.heightAnchor.constraint(equalToConstant: 40),

            summaryLabel.topAnchor.constraint(equalTo: sendMoneyButton.bottomAnchor, constant: 25),
            summaryLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            savingsCard.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 10),
            savingsCard.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            savingsCard.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            checkingCard.topAnchor.constraint(equalTo: savingsCard.bottomAnchor, constant: 15),
            checkingCard.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            checkingCard.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            creditCardLabel.topAnchor.constraint(equalTo: checkingCard.bottomAnchor, constant: 15),
            creditCardLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            creditCardLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            creditCard.topAnchor.constraint(equalTo: creditCardLabel.bottomAnchor, constant: 10),
            creditCard.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            creditCard.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),

            // Allow flexible space before demoPurposesLabel
            demoPurposesLabel.topAnchor.constraint(greaterThanOrEqualTo: creditCard.bottomAnchor, constant: 20),
            demoPurposesLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            demoPurposesLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            demoPurposesLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.layoutMarginsGuide.bottomAnchor),
            ])
    }
}

// MARK: - User Info

private extension HomeViewController {
    func fetchUserInfoIfNeeded() {
        // For the time being we'll treat session state as being "authenticated" even if the access
        // token lapses in the backing endpoint / user defaults.
        //
        // To mask this, we'll only fetch user info once at launch and  ignore after. If we want to
        // refresh user info, log out and log back in.
        guard userInfo == nil else { return }

        serviceAPI.getUserInfo() { [weak self] userInfo, error in

            guard error == nil else {
                self?.handleNetworkError(error: error!)
                return
            }

            self?.userInfo = userInfo
        }
    }
    
    func updateUserInfo() {
        userInfoCard.userInfo = userInfo
    }

}

extension UIView {
    func addBankShadow() {
        // Shadows
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        layer.shadowRadius = 4.0
        //FIXME: cgcolor should be set in updateSubviews to accomodate trait changes (light/dark mode)
        layer.shadowColor = Colors.transShadow.value.cgColor
        layer.masksToBounds = false
        layer.shadowOpacity = 1.0
    }
}
