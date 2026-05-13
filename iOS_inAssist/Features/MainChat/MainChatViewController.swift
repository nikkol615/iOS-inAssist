import UIKit
import SafariServices
import AVFoundation

final class MainChatViewController: UIViewController {

    // MARK: - Properties

    private var items: [ChatItem] = []
    private var currentChatId: Int?
    private var keyboardHeight: CGFloat = 0
    private var isWaitingForResponse = false
    private let voiceRecorder = VoiceRecorder()

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
        label.text = "Что планируем сегодня?"
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
        view.backgroundColor = AppColors.white
        view.layer.cornerRadius = AppCornerRadius.extraLarge
        AppShadows.card(view)
        return view
    }()
    
    private let inputField: UITextField = {
        let field = UITextField()
        field.placeholder = "Напишите запрос..."
        field.font = AppFonts.bodyMedium
        field.textColor = AppColors.primaryText
        field.returnKeyType = .send
        return field
    }()
    
    private let micButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.googleBlue
        button.layer.cornerRadius = 18
        button.tintColor = .white

        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        button.setImage(UIImage(systemName: "mic.fill", withConfiguration: config), for: .normal)

        AppShadows.small(button)
        return button
    }()
    
    private var bottomContainerBottom: NSLayoutConstraint?
    
    private let suggestions = [
        "Что запланировано на сегодня?",
        "Найди свободный час вечером",
        "Свободен ли вечер вторника?"
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupKeyboardObservers()
        setupVoiceRecorder()
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
        tableView.register(EventPreviewCardCell.self, forCellReuseIdentifier: "previewCard")
        tableView.register(MeetEventCell.self, forCellReuseIdentifier: "meetCard")
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
        
        let bottomBottomConstraint = bottomContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomContainerBottom = bottomBottomConstraint

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
            bottomBottomConstraint,

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
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = AppColors.primaryText
        config.background.backgroundColor = AppColors.cardBackground
        config.background.cornerRadius = AppCornerRadius.small
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)

        if let icon = icon {
            config.image = UIImage(systemName: icon,
                                   withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        } else if let text = text {
            config.title = text
        }

        let button = UIButton(configuration: config)
        button.titleLabel?.font = AppFonts.bodySmall
        AppShadows.card(button)
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
            greeting = "Доброе утро"
        case 12..<17:
            greeting = "Добрый день"
        case 17..<22:
            greeting = "Добрый вечер"
        default:
            greeting = "Доброй ночи"
        }

        let firstName = UserDefaults.standard.string(forKey: "inassist.user.firstName")
        if let name = firstName, !name.isEmpty {
            greetingLabel.text = "\(greeting), \(name)!"
        } else if let user = SessionStore.shared.currentUser {
            let name = user.email.components(separatedBy: "@").first?.capitalized ?? "Пользователь"
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
                    // pendingConfirmation = false для всех исторических сообщений (уже обработаны)
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
        let calVC = CalendarViewController()
        calVC.modalPresentationStyle = .pageSheet
        if let sheet = calVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(calVC, animated: true)
    }
    
    // MARK: - Voice Recorder Setup

    private func setupVoiceRecorder() {
        voiceRecorder.onStateChange = { [weak self] state in
            self?.updateMicButton(for: state)
        }
        voiceRecorder.onTranscript = { [weak self] text in
            guard let self else { return }
            self.inputField.text = text
            // Вставляем текст — пользователь видит его и может нажать отправить
            // (не автоотправляем, чтобы дать возможность проверить)
        }
        voiceRecorder.onError = { [weak self] error in
            self?.showAlert(message: error.localizedDescription)
        }
    }

    private func updateMicButton(for state: VoiceRecorder.State) {
        let symCfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        switch state {
        case .idle:
            micButton.setImage(UIImage(systemName: "mic.fill", withConfiguration: symCfg), for: .normal)
            micButton.backgroundColor = AppColors.googleBlue
            micButton.tintColor = .white
            micButton.layer.removeAllAnimations()
            micButton.transform = .identity

        case .recording:
            micButton.setImage(UIImage(systemName: "stop.fill", withConfiguration: symCfg), for: .normal)
            micButton.backgroundColor = .systemRed
            micButton.tintColor = .white
            // Пульсирующая анимация
            UIView.animate(
                withDuration: 0.6,
                delay: 0,
                options: [.repeat, .autoreverse, .curveEaseInOut],
                animations: { self.micButton.transform = CGAffineTransform(scaleX: 1.18, y: 1.18) }
            )

        case .processing:
            micButton.layer.removeAllAnimations()
            micButton.transform = .identity
            micButton.setImage(nil, for: .normal)
            micButton.backgroundColor = AppColors.googleBlue
            // Показываем спиннер поверх кнопки
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.color = .white
            spinner.tag = 999
            spinner.translatesAutoresizingMaskIntoConstraints = false
            micButton.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: micButton.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: micButton.centerYAnchor),
            ])
            spinner.startAnimating()
        }

        // Убираем спиннер при выходе из .processing
        if state != .processing {
            micButton.viewWithTag(999)?.removeFromSuperview()
        }

        // Блокируем поле ввода во время записи/обработки (ТЗ 4.1.4.9.3)
        let isActive = state == .idle
        inputField.isEnabled = isActive
        inputField.alpha = isActive ? 1.0 : 0.4
    }

    @objc private func handleMicTap() {
        switch voiceRecorder.currentState {
        case .idle:
            voiceRecorder.requestPermissionAndStart()
        case .recording:
            voiceRecorder.stop()
        case .processing:
            break  // не прерываем загрузку
        }
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
            showAlert(message: "Сначала войдите в аккаунт")
            return
        }

        inputField.text = nil
        inputField.resignFirstResponder()

        items.append(ChatItem(sender: .user, text: text, link: nil, pendingConfirmation: false))
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
                    if let cid = response.chatID {
                        self.currentChatId = cid
                    }
                    if response.eventCreated == false {
                        self.items.append(ChatItem(
                            sender: .assistant,
                            text: response.summary ?? "",
                            link: nil,
                            eventStart: response.eventStart,
                            eventEnd: response.eventEnd,
                            eventLocation: response.eventLocation,
                            eventDescription: response.eventDescription,
                            pendingConfirmation: true
                        ))
                    } else {
                        self.items.append(ChatItem(
                            sender: .assistant,
                            text: response.summary ?? "Готово",
                            link: response.htmlLink
                        ))
                    }
                case .failure(let error):
                    self.items.append(ChatItem(sender: .assistant, text: Self.friendlyError(error), link: nil))
                }
                self.tableView.reloadData()
                self.scrollToBottom(animated: true)
            }
        }
    }
    
    private static func friendlyError(_ error: Error) -> String {
        // Пробуем вытащить detail из HTTP-ответа сервера (APIError.server)
        if let apiError = error as? APIError, case APIError.server(let msg) = apiError {
            return msg
        }
        let ns = error as NSError
        switch ns.code {
        case NSURLErrorTimedOut,
             NSURLErrorNetworkConnectionLost:
            return "Ассистент думает дольше обычного. Попробуйте ещё раз."
        case NSURLErrorNotConnectedToInternet:
            return "Нет подключения к интернету."
        case NSURLErrorCannotConnectToHost:
            return "Сервер недоступен. Попробуйте позже."
        default:
            // Если сервер вернул HTTP-ошибку с текстом — показываем её
            if let msg = ns.userInfo[NSLocalizedDescriptionKey] as? String,
               !msg.hasPrefix("The "), !msg.hasPrefix("A ") {
                return msg
            }
            return "Не удалось отправить запрос. Попробуйте ещё раз."
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Уведомление", message: message, preferredStyle: .alert)
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

        // Подтверждённое событие с ссылкой → meet-карточка (meet.jpg)
        if item.sender == .assistant && !item.pendingConfirmation && item.link != nil {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "meetCard", for: indexPath) as? MeetEventCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            cell.onJoinMeet = { [weak self] url in
                let safari = SFSafariViewController(url: url)
                self?.present(safari, animated: true)
            }
            cell.onOpenCalendar = { [weak self] url in
                let safari = SFSafariViewController(url: url)
                self?.present(safari, animated: true)
            }
            return cell
        }

        if item.pendingConfirmation {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "previewCard", for: indexPath) as? EventPreviewCardCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            cell.onConfirm = { [weak self] in
                guard let self else { return }
                // Убираем карточку из списка
                if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items.remove(at: idx)
                }
                self.inputField.text = "Да, создай"
                self.handleSend()
            }
            cell.onEdit = { [weak self] suggestion in
                guard let self else { return }
                self.inputField.text = suggestion
                self.inputField.becomeFirstResponder()
            }
            cell.onCancel = { [weak self] in
                guard let self else { return }
                if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items.remove(at: idx)
                    self.tableView.deleteRows(at: [IndexPath(row: idx, section: 0)], with: .fade)
                }
            }
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? ModernChatCell else {
            return UITableViewCell()
        }
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
