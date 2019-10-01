//
//  HomeViewController.swift
//
//  © 2018 AT&T INTELLECTUAL PROPERTY. ALL RIGHTS RESERVED. AT&T PROPRIETARY / CONFIDENTIAL MATERIALS AND AN AT&T CONTRIBUTED ITEM UNDER THE EXPENSE AND INFORMATION SHARING AGREEMENT DATED FEBRUARY 7, 2018.
//

import UIKit

class HomeViewController: UIViewController {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Welcome!"
        label.font = UIFont.systemFont(ofSize: 24)
//        label.textAlignment = .center
        return label
    }()

    let userInfoLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
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

    let userInfoCard: UIView = {
        let card = UIView()
        card.backgroundColor = Colors.white.value
        card.translatesAutoresizingMaskIntoConstraints = false
        let avatar = UIImageView(image: UIImage(named: "profile"))
        avatar.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(avatar)

        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 15),
            avatar.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
            ])
        card.addBankShadow()
        return card
    }()

    let savingsCard: AccountCard = {
        let card = AccountCard("Savings", icon: UIImage(named: "pig") ?? UIImage())
        card.translatesAutoresizingMaskIntoConstraints = false

        return card
    }()

    let checkingCard: AccountCard = {
        let card = AccountCard("Checking", icon: UIImage(named: "check") ?? UIImage())
        card.translatesAutoresizingMaskIntoConstraints = false

        return card
    }()

    let creditCard: AccountCard = {
        let card = AccountCard("Premier Reserve", icon: UIImage(named: "creditCard") ?? UIImage())
        card.translatesAutoresizingMaskIntoConstraints = false

        return card
    }()

//    let viewHistoryButton: BankAppButton = {
//        let button = BankAppButton()
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.setTitle("View History", for: .normal)
//        button.addTarget(self, action: #selector(viewHistoryTouched(_:)), for: .touchUpInside)
//        button.backgroundColor = UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0)
//        return button
//    }()

//    let logoutButton: BankAppButton = {
//        let button = BankAppButton()
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.setTitle("Logout", for: .normal)
//        button.addTarget(self, action: #selector(logoutButtonTouched(_:)), for: .touchUpInside)
//        button.backgroundColor = UIColor(red: 0.36, green: 0.56, blue: 0.93, alpha: 1.0)
//        return button
//    }()

    private var userInfo: UserInfo? {
        didSet {
            updateUserInfo()
        }
    }

    private var serviceAPI: ServiceProviderAPIProtocol = BuildInfo.serviceProviderAPI()

    override func loadView() {
        let backgroundGradient = GradientView()
        backgroundGradient.startColor = Colors.white.value
        backgroundGradient.endColor = Colors.gradientMax.value
        backgroundGradient.startLocation = 0.0
        backgroundGradient.endLocation = 1.0
        view = backgroundGradient

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutView()
        title = "Home"

        // Hamburger
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(viewHistoryTouched(_:)))
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
        view.backgroundColor = .white
        let safeAreaGuide = getSafeLayoutGuide()
        
        view.addSubview(titleLabel)
        view.addSubview(userInfoCard)
        view.addSubview(sendMoneyButton)
        view.addSubview(savingsCard)
        view.addSubview(checkingCard)
        view.addSubview(creditCard)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: safeAreaGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            titleLabel.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),

            userInfoCard.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            userInfoCard.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            userInfoCard.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),

            sendMoneyButton.topAnchor.constraint(equalTo: userInfoCard.bottomAnchor, constant: 20),
            sendMoneyButton.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            sendMoneyButton.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),
            sendMoneyButton.heightAnchor.constraint(equalToConstant: 40),

            savingsCard.topAnchor.constraint(equalTo: sendMoneyButton.bottomAnchor, constant: 50),
            savingsCard.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            savingsCard.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),

            checkingCard.topAnchor.constraint(equalTo: savingsCard.bottomAnchor, constant: 15),
            checkingCard.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            checkingCard.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),

            creditCard.topAnchor.constraint(equalTo: checkingCard.bottomAnchor, constant: 15),
            creditCard.leadingAnchor.constraint(equalTo: safeAreaGuide.leadingAnchor, constant: 25),
            creditCard.trailingAnchor.constraint(equalTo: safeAreaGuide.trailingAnchor, constant: -25),

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
        guard let userInfo = userInfo else {
            userInfoLabel.text = nil
            return
        }

        userInfoLabel.text = """
        user: \(userInfo.username)
        name: \(userInfo.name ?? "{name}") | phone: \(userInfo.phone ?? "{phone}")
        email: \(userInfo.email ?? "{email}") | zip: \(userInfo.postalCode ?? "{postal code}")
        """
    }

//    func accountCard(_ text: String, icon: UIImage) -> UIView {
//        let card = UIView()
//
//        card.addBankShadow()
//        return card
//    }
}

class AccountCard: UIView {
    let backgroundImage: UIImageView
    init(_ text: String, icon: UIImage) {
        self.backgroundImage = UIImageView(image: icon)
        super.init(frame: .zero)
        layout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout() {
        backgroundColor = Colors.white.value
        addSubview(backgroundImage)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundImage.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            backgroundImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            backgroundImage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            ])
        addBankShadow()
    }
}

extension UIView {
    func addBankShadow() {
        // Shadows
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        layer.shadowRadius = 4.0
        //FIXME: cgcolor should be set in updateSubviews to accomodate trait changes (light/dark mode)
        // make color asset wityh alpha?
        layer.shadowColor = Colors.shadow.value.cgColor
        layer.masksToBounds = false
        layer.shadowOpacity = 1.0
        //        card.layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        //        card.layer.shouldRasterize = true
        //        card.layer.rasterizationScale = scale ? UIScreen.main.scale : 1

    }
}
