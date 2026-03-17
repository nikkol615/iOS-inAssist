import UIKit
import SafariServices

final class MainChatViewController: UIViewController {

    // MARK: - Properties

    private var items: [ChatItem] = []
    private var currentChatId: Int?
    private var keyboardHeight: CGFloat = 0
    private var isWaitingForResponse = false

    // MARK: - UI Elements
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let menuButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.cardBackground
        button.layer.cornerRadius = 20
        button.tintColor = AppColors.primaryText
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "square.grid.2x2", withConfiguration: config), for: .normal)
        
        AppShadows.small(button)
        return button
    }()
    
    private let calendarButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.cardBackground
        button.layer.cornerRadius = 20
        button.tintColor = AppColors.primaryText
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "calendar", withConfiguration: config), for: .normal)
        
        AppShadows.small(button)
        return button
    }()
    
    private let profileButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.cardBackground
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "person.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = AppColors.primaryText
        
        AppShadows.small(button)
        return button
    }()
    
    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = AppFonts.bodyLarge
        label.textColor = AppColors.secondaryText
        label.textAlignment = .center
        return label
    }()
    
    private let mainTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "What are we planning for today?"
        label.font = AppFonts.titleMedium
        label.textColor = AppColors.primaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let welcomeContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.keyboardDismissMode = .interactive
        table.allowsSelection = false
        table.backgroundColor = .clear
        table.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        return table
    }()
    
    private let bottomContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    private let suggestionsScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        return scroll
    }()
    
    private let suggestionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let inputContainer: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppCornerRadius.extraLarge
        AppShadows.card(view)
        return view
    }()
    
    private let inputField: UITextField = {
        let field = UITextField()
        field.placeholder = "Ask anything"
        field.font = AppFonts.bodyMedium
        field.textColor = AppColors.primaryText
        field.returnKeyType = .send
        return field
    }()
    
    private let micButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 0.5
        button.layer.borderColor = AppColors.inputBorder.cgColor
        button.tintColor = AppColors.primaryText
        
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)
        
        AppShadows.small(button)
        return button
    }()
    
    private var bottomContainerBottom: NSLayoutConstraint?
    
    private let suggestions = [
        "What do I've planned for today?",
        "Find a free hour tonight",
        "Is Tuesday evening free?"
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardObservers()
        updateGreeting()
        loadOrCreateChat()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = AppColors.background

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [AppColors.gradientStart.cgColor, AppColors.gradientEnd.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)

        view.addSubview(headerView)
        headerView.addSubview(menuButton)
        headerView.addSubview(calendarButton)
        headerView.addSubview(profileButton)

        view.addSubview(welcomeContainer)
        welcomeContainer.addSubview(greetingLabel)
        welcomeContainer.addSubview(mainTitleLabel)

        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ModernChatCell.self, forCellReuseIdentifier: "cell")
        tableView.register(TypingIndicatorCell.self, forCellReuseIdentifier: "typingCell")
        tableView.isHidden = true

        view.addSubview(bottomContainer)
        bottomContainer.addSubview(suggestionsScrollView)
        suggestionsScrollView.addSubview(suggestionsStack)
        bottomContainer.addSubview(inputContainer)
        inputContainer.addSubview(inputField)
        inputContainer.addSubview(micButton)

        setupSuggestionChips()
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        [headerView, menuButton, calendarButton, profileButton,
         welcomeContainer, greetingLabel, mainTitleLabel,
         tableView, bottomContainer, suggestionsScrollView, suggestionsStack,
         inputContainer, inputField, micButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        bottomContainerBottom = bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 76),
            
            menuButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 32),
            menuButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 6),
            menuButton.widthAnchor.constraint(equalToConstant: 40),
            menuButton.heightAnchor.constraint(equalToConstant: 40),
            
            profileButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -32),
            profileButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 6),
            profileButton.widthAnchor.constraint(equalToConstant: 40),
            profileButton.heightAnchor.constraint(equalToConstant: 40),
            
            calendarButton.trailingAnchor.constraint(equalTo: profileButton.leadingAnchor, constant: -12),
            calendarButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 6),
            calendarButton.widthAnchor.constraint(equalToConstant: 40),
            calendarButton.heightAnchor.constraint(equalToConstant: 40),

            welcomeContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            welcomeContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            welcomeContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            greetingLabel.topAnchor.constraint(equalTo: welcomeContainer.topAnchor),
            greetingLabel.leadingAnchor.constraint(equalTo: welcomeContainer.leadingAnchor),
            greetingLabel.trailingAnchor.constraint(equalTo: welcomeContainer.trailingAnchor),
            
            mainTitleLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 10),
            mainTitleLabel.leadingAnchor.constraint(equalTo: welcomeContainer.leadingAnchor),
            mainTitleLabel.trailingAnchor.constraint(equalTo: welcomeContainer.trailingAnchor),
            mainTitleLabel.bottomAnchor.constraint(equalTo: welcomeContainer.bottomAnchor),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomContainer.topAnchor),

            bottomContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomContainerBottom!,

            suggestionsScrollView.topAnchor.constraint(equalTo: bottomContainer.topAnchor),
            suggestionsScrollView.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor),
            suggestionsScrollView.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor),
            suggestionsScrollView.heightAnchor.constraint(equalToConstant: 50),
            
            suggestionsStack.topAnchor.constraint(equalTo: suggestionsScrollView.topAnchor),
            suggestionsStack.leadingAnchor.constraint(equalTo: suggestionsScrollView.leadingAnchor),
            suggestionsStack.trailingAnchor.constraint(equalTo: suggestionsScrollView.trailingAnchor),
            suggestionsStack.heightAnchor.constraint(equalTo: suggestionsScrollView.heightAnchor),

            inputContainer.topAnchor.constraint(equalTo: suggestionsScrollView.bottomAnchor, constant: 14),
            inputContainer.leadingAnchor.constraint(equalTo: bottomContainer.leadingAnchor, constant: 8),
            inputContainer.trailingAnchor.constraint(equalTo: bottomContainer.trailingAnchor, constant: -8),
            inputContainer.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor, constant: -24),
            inputContainer.heightAnchor.constraint(equalToConstant: 56),

            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 24),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.trailingAnchor.constraint(equalTo: micButton.leadingAnchor, constant: -16),

            micButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -10),
            micButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            micButton.widthAnchor.constraint(equalToConstant: 36),
            micButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupSuggestionChips() {
        let newChatChip = createChipButton(icon: "plus", text: nil)
        newChatChip.addTarget(self, action: #selector(handleNewChat), for: .touchUpInside)
        suggestionsStack.addArrangedSubview(newChatChip)

        for suggestion in suggestions {
            let chip = createChipButton(icon: nil, text: suggestion)
            chip.addTarget(self, action: #selector(handleSuggestionTap(_:)), for: .touchUpInside)
            suggestionsStack.addArrangedSubview(chip)
        }
    }
    
    private func createChipButton(icon: String?, text: String?) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.cardBackground
        button.layer.cornerRadius = AppCornerRadius.small
        button.tintColor = AppColors.primaryText
        AppShadows.card(button)
        
        if let icon = icon {
            let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .medium)
            button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        } else if let text = text {
            button.setTitle(text, for: .normal)
            button.titleLabel?.font = AppFonts.bodySmall
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        }
        
        return button
    }
    
    private func setupActions() {
        inputField.delegate = self
        menuButton.addTarget(self, action: #selector(handleMenuTap), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(handleProfileTap), for: .touchUpInside)
        calendarButton.addTarget(self, action: #selector(handleCalendarTap), for: .touchUpInside)
        micButton.addTarget(self, action: #selector(handleMicTap), for: .touchUpInside)
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Helpers
    
    private func updateGreeting() {
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
        } else {
            greetingLabel.text = "\(greeting)!"
        }
    }

    private func loadOrCreateChat() {
        guard let user = SessionStore.shared.currentUser else { return }

        APIClient.shared.listChats(user: user) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let chats):
                    if let lastChat = chats.last {
                        self.currentChatId = lastChat.id
                        self.loadHistory()
                    }
                case .failure:
                    break
                }
            }
        }
    }

    private func loadHistory() {
        guard let user = SessionStore.shared.currentUser else { return }

        APIClient.shared.fetchHistory(user: user, chatId: currentChatId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let messages):
                    if !messages.isEmpty {
                        self.items = messages.map { msg in
                            let sender: ChatItem.Sender = (msg.role == "user") ? .user : .assistant
                            return ChatItem(sender: sender, text: msg.text, link: msg.htmlLink)
                        }
                        self.showChatMode()
                    }
                case .failure:
                    break
                }
            }
        }
    }
    
    private func showChatMode() {
        welcomeContainer.isHidden = true
        tableView.isHidden = false
        tableView.reloadData()
        scrollToBottom(animated: false)
    }
    
    private func showWelcomeMode() {
        welcomeContainer.isHidden = false
        tableView.isHidden = true
    }
    
    private func scrollToBottom(animated: Bool) {
        guard !items.isEmpty else { return }
        let indexPath = IndexPath(row: items.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    // MARK: - Actions
    
    @objc private func handleMenuTap() {
        let menuVC = MenuViewController()
        menuVC.delegate = self
        menuVC.modalPresentationStyle = .overFullScreen
        menuVC.modalTransitionStyle = .crossDissolve
        present(menuVC, animated: true)
    }
    
    @objc private func handleProfileTap() {
        let profileVC = ProfileViewController()
        profileVC.modalPresentationStyle = .pageSheet
        if let sheet = profileVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(profileVC, animated: true)
    }
    
    @objc private func handleCalendarTap() {
        openGoogleCalendar()
    }

    private func openGoogleCalendar() {
        guard let url = URL(string: "https://calendar.google.com/calendar/u/0/r") else { return }
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let safari = SFSafariViewController(url: url, configuration: config)
        present(safari, animated: true)
    }
    
    @objc private func handleMicTap() {
    }
    
    @objc private func handleNewChat() {
        guard let user = SessionStore.shared.currentUser else { return }

        APIClient.shared.createChat(user: user) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let chat):
                    self.currentChatId = chat.id
                    self.items = []
                    self.showWelcomeMode()
                case .failure(let error):
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func handleSuggestionTap(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        inputField.text = text
        handleSend()
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        keyboardHeight = keyboardFrame.height
        bottomContainerBottom?.constant = -keyboardHeight + view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        keyboardHeight = 0
        bottomContainerBottom?.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }

    private func handleSend() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        guard let user = SessionStore.shared.currentUser else {
            showAlert(message: "Please sign in first")
            return
        }

        inputField.text = nil
        inputField.resignFirstResponder()

        items.append(ChatItem(sender: .user, text: text, link: nil))
        showChatMode()
        isWaitingForResponse = true
        tableView.reloadData()
        scrollToBottom(animated: true)

        APIClient.shared.sendChat(text: text, user: user, chatId: currentChatId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isWaitingForResponse = false
                switch result {
                case .success(let response):
                    let responseText = response.summary ?? "Event created"
                    self.items.append(ChatItem(sender: .assistant, text: responseText, link: response.htmlLink))
                case .failure(let error):
                    self.items.append(ChatItem(sender: .assistant, text: "Error: \(error.localizedDescription)", link: nil))
                }
                self.tableView.reloadData()
                self.scrollToBottom(animated: true)
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension MainChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count + (isWaitingForResponse ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isWaitingForResponse && indexPath.row == items.count {
            return tableView.dequeueReusableCell(withIdentifier: "typingCell", for: indexPath)
        }
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ModernChatCell
        cell.configure(with: item)
        cell.onOpenLink = { [weak self] link in
            let safari = SFSafariViewController(url: link)
            self?.present(safari, animated: true)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MainChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

// MARK: - UITextFieldDelegate

extension MainChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}

// MARK: - MenuViewControllerDelegate

extension MainChatViewController: MenuViewControllerDelegate {
    func menuDidSelectChat(_ chatId: Int) {
        currentChatId = chatId
        items = []
        loadHistory()
    }

    func menuDidRequestNewChat() {
        handleNewChat()
    }

    func menuDidOpenCalendar() {
        openGoogleCalendar()
    }
}

// MARK: - TypingIndicatorCell

private final class TypingIndicatorCell: UITableViewCell {
    private let bubbleView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColors.cardBackground
        view.layer.cornerRadius = AppCornerRadius.medium
        return view
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.text = "Печатает..."
        label.font = AppFonts.bodyMedium
        label.textColor = AppColors.secondaryText
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(label)
        [bubbleView, label].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 120),
            label.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
