import UIKit

final class ProfileViewController: UIViewController {

    // MARK: - UI Elements

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Close", for: .normal)
        button.titleLabel?.font = AppFonts.bodyLarge
        button.tintColor = AppColors.primaryText
        return button
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = AppColors.cardBackground
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        imageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        imageView.tintColor = AppColors.primaryText
        
        AppShadows.small(imageView)
        return imageView
    }()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.titleMedium
        label.textColor = AppColors.primaryText
        label.textAlignment = .center
        return label
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bodyLarge
        label.textColor = AppColors.secondaryText
        label.textAlignment = .center
        return label
    }()
    
    private let menuContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground.withAlphaComponent(0.1)
        view.layer.cornerRadius = AppCornerRadius.extraLarge
        return view
    }()
    
    private let menuStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 22
        stack.alignment = .fill
        return stack
    }()
    
    private let menuItems: [(icon: String, title: String)] = [
        ("shield", "Privacy Center"),
        ("gearshape", "Settings"),
        ("exclamationmark.triangle", "Report a problem"),
        ("questionmark.circle", "Help"),
        ("rectangle.portrait.and.arrow.right", "Log out")
    ]

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUserInfo()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(closeButton)
        view.addSubview(avatarImageView)
        view.addSubview(greetingLabel)
        view.addSubview(emailLabel)
        view.addSubview(menuContainer)
        menuContainer.addSubview(menuStack)

        setupMenuItems()
        setupConstraints()
        
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }
    
    private func setupMenuItems() {
        for (index, item) in menuItems.enumerated() {
            let menuRow = createMenuRow(icon: item.icon, title: item.title, isLogout: index == menuItems.count - 1)
            menuRow.tag = index
            menuRow.addTarget(self, action: #selector(handleMenuItemTap(_:)), for: .touchUpInside)
            menuStack.addArrangedSubview(menuRow)
        }
    }
    
    private func createMenuRow(icon: String, title: String, isLogout: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = isLogout ? .systemRed : AppColors.primaryText
        
        var config = UIButton.Configuration.plain()
        config.imagePadding = 12
        config.baseForegroundColor = isLogout ? .systemRed : AppColors.primaryText
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        config.image = UIImage(systemName: icon, withConfiguration: iconConfig)
        
        var titleAttr = AttributedString(title)
        titleAttr.font = AppFonts.bodyLarge
        config.attributedTitle = titleAttr
        
        button.configuration = config
        button.contentHorizontalAlignment = .leading

        if !isLogout {
            let chevron = UIImageView()
            chevron.translatesAutoresizingMaskIntoConstraints = false
            let chevronConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            chevron.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
            chevron.tintColor = AppColors.secondaryText
            button.addSubview(chevron)
            
            NSLayoutConstraint.activate([
                chevron.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                chevron.centerYAnchor.constraint(equalTo: button.centerYAnchor)
            ])
        }
        
        return button
    }
    
    private func setupConstraints() {
        [closeButton, avatarImageView, greetingLabel, emailLabel, menuContainer, menuStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            avatarImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            greetingLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            greetingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            greetingLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 10),
            emailLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            menuContainer.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 24),
            menuContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            menuContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            menuStack.topAnchor.constraint(equalTo: menuContainer.topAnchor, constant: 16),
            menuStack.leadingAnchor.constraint(equalTo: menuContainer.leadingAnchor, constant: 20),
            menuStack.trailingAnchor.constraint(equalTo: menuContainer.trailingAnchor, constant: -20),
            menuStack.bottomAnchor.constraint(equalTo: menuContainer.bottomAnchor, constant: -16)
        ])
    }
    
    // MARK: - Data
    
    private func updateUserInfo() {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 5..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        case 17..<22:
            greeting = "Good evening"
        default:
            greeting = "Good night"
        }

        if let user = SessionStore.shared.currentUser {
            let name = user.email.components(separatedBy: "@").first?.capitalized ?? "User"
            greetingLabel.text = "\(greeting), \(name)!"
            emailLabel.text = user.email
        } else {
            greetingLabel.text = "\(greeting)!"
            emailLabel.text = ""
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleClose() {
        dismiss(animated: true)
    }

    @objc private func handleMenuItemTap(_ sender: UIButton) {
        switch sender.tag {
        case 0: break
        case 1: break
        case 2: break
        case 3: break
        case 4: handleLogout()
        default: break
        }
    }

    private func handleLogout() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
            SessionStore.shared.currentUser = nil

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                let onboardingVC = OnboardingViewController()
                let nav = UINavigationController(rootViewController: onboardingVC)
                window.rootViewController = nav
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
            }

            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
