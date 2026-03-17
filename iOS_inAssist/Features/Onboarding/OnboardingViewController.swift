import UIKit
import AuthenticationServices

final class OnboardingViewController: UIViewController {

    // MARK: - UI Elements

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "message.circle.fill")
        imageView.tintColor = AppColors.black
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to Ai"
        label.font = AppFonts.titleLarge
        label.textColor = AppColors.primaryText
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sign in with Google to start planning your meetings with AI."
        label.font = AppFonts.bodyLarge
        label.textColor = AppColors.secondaryText
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let googleButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.buttonBackground
        button.layer.cornerRadius = AppCornerRadius.large
        button.layer.borderWidth = 1
        button.layer.borderColor = AppColors.buttonBorder.cgColor

        var config = UIButton.Configuration.plain()
        config.imagePadding = 16
        config.baseForegroundColor = .white

        let googleIcon = UIImage(systemName: "g.circle.fill")?.withRenderingMode(.alwaysTemplate)
        config.image = googleIcon

        var titleAttr = AttributedString("Sign in with Google")
        titleAttr.font = AppFonts.button
        config.attributedTitle = titleAttr

        button.configuration = config
        return button
    }()

    private let spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = AppColors.secondaryText
        return indicator
    }()

    private var authSession: ASWebAuthenticationSession?

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

        [iconImageView, titleLabel, subtitleLabel, googleButton, spinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        AppShadows.button(googleButton)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -120),
            iconImageView.widthAnchor.constraint(equalToConstant: 200),
            iconImageView.heightAnchor.constraint(equalToConstant: 200),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            googleButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            googleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleButton.widthAnchor.constraint(equalToConstant: 320),
            googleButton.heightAnchor.constraint(equalToConstant: 60),

            spinner.topAnchor.constraint(equalTo: googleButton.bottomAnchor, constant: 20),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupActions() {
        googleButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func handleGoogleSignIn() {
        setLoading(true)

        APIClient.shared.fetchAuthURL { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let url):
                    self.presentAuthSession(url: url)
                case .failure(let error):
                    self.setLoading(false)
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func presentAuthSession(url: URL) {
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: APIConfig.redirectScheme) { [weak self] callbackURL, error in
            guard let self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.setLoading(false)
                    if (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.showAlert(message: error.localizedDescription)
                    }
                }
                return
            }

            guard
                let callbackURL,
                let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
            else {
                DispatchQueue.main.async {
                    self.setLoading(false)
                    self.showAlert(message: APIError.missingCode.localizedDescription)
                }
                return
            }

            if let userId = components.queryItems?.first(where: { $0.name == "user_id" })?.value {
                let email = components.queryItems?.first(where: { $0.name == "email" })?.value ?? ""
                let sessionUser = SessionUser(userID: userId, email: email, expiresAt: nil)
                SessionStore.shared.currentUser = sessionUser
                DispatchQueue.main.async {
                    self.setLoading(false)
                    self.navigateToChat()
                }
                return
            }

            guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                DispatchQueue.main.async {
                    self.setLoading(false)
                    self.showAlert(message: APIError.missingCode.localizedDescription)
                }
                return
            }

            self.finishAuth(code: code)
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        session.start()
        authSession = session
    }

    private func finishAuth(code: String) {
        APIClient.shared.completeAuth(code: code, redirectURI: APIConfig.redirectURI) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success(let user):
                    SessionStore.shared.currentUser = user
                    self.setLoading(false)
                    self.navigateToChat()
                case .failure(let error):
                    self.setLoading(false)
                    self.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func navigateToChat() {
        let chatVC = MainChatViewController()
        navigationController?.setViewControllers([chatVC], animated: true)
    }

    private func setLoading(_ loading: Bool) {
        googleButton.isEnabled = !loading
        googleButton.alpha = loading ? 0.6 : 1.0
        loading ? spinner.startAnimating() : spinner.stopAnimating()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension OnboardingViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}
