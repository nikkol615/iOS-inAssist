import UIKit

// MARK: - NameEntryViewController
// Figma: onboarding2.jpg — "How should I address you?"
// Шаг 2 онбординга: пользователь вводит имя и фамилию.
// Данные сохраняются в SessionStore и опционально отправляются на Backend.

final class NameEntryViewController: UIViewController {

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Как к вам обращаться?"
        l.font = AppFonts.sfProDisplayBold(28)
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    private let firstNameField: _RoundedTextField = {
        let f = _RoundedTextField()
        f.placeholder = "Имя"
        return f
    }()

    private let lastNameField: _RoundedTextField = {
        let f = _RoundedTextField()
        f.placeholder = "Фамилия"
        f.returnKeyType = .done
        return f
    }()

    private let continueButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Продолжить", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = AppFonts.button
        b.backgroundColor = AppColors.accentBlue
        b.layer.cornerRadius = AppCornerRadius.large
        AppShadows.button(b)
        return b
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.color = .white
        s.hidesWhenStopped = true
        return s
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = AppColors.background

        [titleLabel, firstNameField, lastNameField, continueButton, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        continueButton.addSubview(spinner)
        spinner.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            firstNameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            firstNameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            firstNameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            firstNameField.heightAnchor.constraint(equalToConstant: 56),

            lastNameField.topAnchor.constraint(equalTo: firstNameField.bottomAnchor, constant: 12),
            lastNameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            lastNameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            lastNameField.heightAnchor.constraint(equalToConstant: 56),

            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 56),

            spinner.centerXAnchor.constraint(equalTo: continueButton.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: continueButton.centerYAnchor),
        ])
    }

    private func setupActions() {
        continueButton.addTarget(self, action: #selector(handleContinue), for: .touchUpInside)
        firstNameField.delegate = self
        lastNameField.delegate = self
    }

    // MARK: - Actions

    @objc private func handleContinue() {
        let firstName = firstNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName  = lastNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Сохраняем имя в UserDefaults для отображения в UI
        UserDefaults.standard.set(firstName, forKey: "inassist.user.firstName")
        UserDefaults.standard.set(lastName,  forKey: "inassist.user.lastName")

        navigateToChat()
    }

    private func navigateToChat() {
        let chatVC = MainChatViewController()
        navigationController?.setViewControllers([chatVC], animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension NameEntryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === firstNameField {
            lastNameField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            handleContinue()
        }
        return true
    }
}

// MARK: - _RoundedTextField

private final class _RoundedTextField: UITextField {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.hex("#ECECEC", default: UIColor(white: 0.93, alpha: 1))
        layer.cornerRadius = AppCornerRadius.medium
        font = AppFonts.bodyLarge
        textColor = AppColors.primaryText
        returnKeyType = .next
        autocorrectionType = .no
        autocapitalizationType = .words
    }

    required init?(coder: NSCoder) { fatalError() }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 16, dy: 0)
    }
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 16, dy: 0)
    }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.insetBy(dx: 16, dy: 0)
    }
}
