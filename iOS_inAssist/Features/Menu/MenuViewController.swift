import UIKit

protocol MenuViewControllerDelegate: AnyObject {
    func menuDidSelectChat(_ chatId: Int)
    func menuDidRequestNewChat()
    func menuDidOpenCalendar()
}

final class MenuViewController: UIViewController {

    weak var delegate: MenuViewControllerDelegate?

    private var chats: [ChatInfo] = []

    // MARK: - UI Elements

    private let dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return view
    }()
    
    private let menuContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Menu"
        label.font = AppFonts.titleMedium
        label.textColor = AppColors.primaryText
        return label
    }()
    
    private let chatsLabel: UILabel = {
        let label = UILabel()
        label.text = "Chats"
        label.font = AppFonts.bodyLarge
        label.textColor = AppColors.primaryText
        return label
    }()
    
    private let chatsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.chipBackground.withAlphaComponent(0.35)
        view.layer.cornerRadius = AppCornerRadius.extraLarge
        view.layer.borderWidth = 1
        view.layer.borderColor = AppColors.divider.cgColor
        return view
    }()
    
    private let chatsTableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.showsVerticalScrollIndicator = false
        return table
    }()
    
    private let calendarButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.cardBackground
        button.layer.cornerRadius = AppCornerRadius.medium
        button.layer.borderWidth = 1
        button.layer.borderColor = AppColors.chipBackground.cgColor
        button.tintColor = AppColors.primaryText
        AppShadows.card(button)
        
        var config = UIButton.Configuration.plain()
        config.imagePadding = 4
        config.baseForegroundColor = AppColors.primaryText
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        config.image = UIImage(systemName: "calendar", withConfiguration: iconConfig)
        
        var titleAttr = AttributedString("My calendar")
        titleAttr.font = AppFonts.sfProDisplayMedium(14)
        config.attributedTitle = titleAttr
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 32, bottom: 14, trailing: 32)
        
        button.configuration = config
        
        return button
    }()
    
    private let userContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = AppColors.cardBackground
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        imageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        imageView.tintColor = AppColors.primaryText
        
        AppShadows.small(imageView)
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.sfProDisplayMedium(16)
        label.textColor = AppColors.primaryText
        return label
    }()
    
    private let userEmailLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bodyMedium
        label.textColor = AppColors.secondaryText
        return label
    }()
    
    private let chevronButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = AppColors.secondaryText
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        calendarButton.addTarget(self, action: #selector(handleCalendarTap), for: .touchUpInside)
        loadChats()
        updateUserInfo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }
    
    // MARK: - Setup
    
    private let contentWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let bottomSpacer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }()

    private func setupUI() {
        view.backgroundColor = .clear

        view.addSubview(dimView)
        view.addSubview(menuContainer)

        menuContainer.addSubview(contentWrapper)
        contentWrapper.addSubview(titleLabel)
        contentWrapper.addSubview(chatsLabel)
        contentWrapper.addSubview(chatsContainer)
        chatsContainer.addSubview(chatsTableView)
        contentWrapper.addSubview(bottomSpacer)
        contentWrapper.addSubview(calendarButton)
        contentWrapper.addSubview(userContainer)

        userContainer.addSubview(avatarImageView)
        userContainer.addSubview(userNameLabel)
        userContainer.addSubview(userEmailLabel)
        userContainer.addSubview(chevronButton)

        chatsTableView.dataSource = self
        chatsTableView.delegate = self
        chatsTableView.register(ChatListCell.self, forCellReuseIdentifier: "chatCell")

        setupConstraints()

        menuContainer.transform = CGAffineTransform(translationX: -320, y: 0)
    }

    private func setupConstraints() {
        [dimView, menuContainer, contentWrapper, bottomSpacer, titleLabel, chatsLabel, chatsContainer, chatsTableView,
         calendarButton, userContainer, avatarImageView, userNameLabel, userEmailLabel, chevronButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            menuContainer.topAnchor.constraint(equalTo: view.topAnchor),
            menuContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            menuContainer.widthAnchor.constraint(equalToConstant: 320),

            contentWrapper.topAnchor.constraint(equalTo: menuContainer.safeAreaLayoutGuide.topAnchor, constant: 12),
            contentWrapper.leadingAnchor.constraint(equalTo: menuContainer.leadingAnchor, constant: 16),
            contentWrapper.trailingAnchor.constraint(equalTo: menuContainer.trailingAnchor, constant: -16),
            contentWrapper.bottomAnchor.constraint(equalTo: menuContainer.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: contentWrapper.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor),

            chatsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            chatsLabel.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor),
            chatsLabel.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor),

            chatsContainer.topAnchor.constraint(equalTo: chatsLabel.bottomAnchor, constant: 12),
            chatsContainer.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor),
            chatsContainer.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor),
            chatsContainer.heightAnchor.constraint(equalToConstant: 280),

            chatsTableView.topAnchor.constraint(equalTo: chatsContainer.topAnchor, constant: 16),
            chatsTableView.leadingAnchor.constraint(equalTo: chatsContainer.leadingAnchor, constant: 20),
            chatsTableView.trailingAnchor.constraint(equalTo: chatsContainer.trailingAnchor, constant: -16),
            chatsTableView.bottomAnchor.constraint(equalTo: chatsContainer.bottomAnchor, constant: -16),

            bottomSpacer.topAnchor.constraint(equalTo: chatsContainer.bottomAnchor, constant: 16),
            bottomSpacer.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor),
            bottomSpacer.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor),
            bottomSpacer.bottomAnchor.constraint(equalTo: calendarButton.topAnchor),

            calendarButton.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor),
            calendarButton.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor),
            calendarButton.heightAnchor.constraint(equalToConstant: 48),

            userContainer.topAnchor.constraint(equalTo: calendarButton.bottomAnchor, constant: 24),
            userContainer.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor),
            userContainer.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor),
            userContainer.heightAnchor.constraint(equalToConstant: 40),
            userContainer.bottomAnchor.constraint(equalTo: contentWrapper.bottomAnchor),

            avatarImageView.leadingAnchor.constraint(equalTo: userContainer.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: userContainer.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            userNameLabel.topAnchor.constraint(equalTo: userContainer.topAnchor),
            userNameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            userNameLabel.trailingAnchor.constraint(equalTo: chevronButton.leadingAnchor, constant: -8),

            userEmailLabel.bottomAnchor.constraint(equalTo: userContainer.bottomAnchor),
            userEmailLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            userEmailLabel.trailingAnchor.constraint(equalTo: chevronButton.leadingAnchor, constant: -8),

            chevronButton.trailingAnchor.constraint(equalTo: userContainer.trailingAnchor),
            chevronButton.centerYAnchor.constraint(equalTo: userContainer.centerYAnchor),
            chevronButton.widthAnchor.constraint(equalToConstant: 15),
            chevronButton.heightAnchor.constraint(equalToConstant: 15)
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimTap))
        dimView.addGestureRecognizer(tapGesture)

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeGesture.direction = .left
        menuContainer.addGestureRecognizer(swipeGesture)
    }
    
    // MARK: - Data
    
    private func loadChats() {
        guard let user = SessionStore.shared.currentUser else { return }

        APIClient.shared.listChats(user: user) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let chats):
                    self.chats = chats
                    self.chatsTableView.reloadData()
                case .failure:
                    break
                }
            }
        }
    }
    
    private func updateUserInfo() {
        if let user = SessionStore.shared.currentUser {
            let name = user.email.components(separatedBy: "@").first?.capitalized ?? "User"
            userNameLabel.text = name
            userEmailLabel.text = user.email
        }
    }
    
    // MARK: - Animation
    
    private func animateIn() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.menuContainer.transform = .identity
            self.dimView.alpha = 1
        }
    }
    
    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            self.menuContainer.transform = CGAffineTransform(translationX: -320, y: 0)
            self.dimView.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleDimTap() {
        animateOut()
    }
    
    @objc private func handleSwipe() {
        animateOut()
    }

    @objc private func handleCalendarTap() {
        animateOut { [weak self] in
            self?.delegate?.menuDidOpenCalendar()
        }
    }
}

// MARK: - UITableViewDataSource

extension MenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as? ChatListCell else {
            return UITableViewCell()
        }
        let chat = chats[indexPath.row]
        cell.configure(with: chat)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chat = chats[indexPath.row]
        animateOut { [weak self] in
            self?.delegate?.menuDidSelectChat(chat.id)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        37
    }
}

// MARK: - ChatListCell

final class ChatListCell: UITableViewCell {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .regular)
        imageView.image = UIImage(systemName: "message", withConfiguration: config)
        imageView.tintColor = AppColors.primaryText
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bodyMedium
        label.textColor = AppColors.primaryText
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        [iconImageView, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    func configure(with chat: ChatInfo) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        if let dateString = chat.createdAt,
           let date = dateFormatter.date(from: String(dateString.prefix(19))) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMM d"
            titleLabel.text = "Chat from \(displayFormatter.string(from: date))"
        } else {
            titleLabel.text = "Chat #\(chat.id)"
        }
    }
}
