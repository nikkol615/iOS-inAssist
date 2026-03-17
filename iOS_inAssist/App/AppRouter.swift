import UIKit

enum AppRouter {

    static func showLogin() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first else { return }
            SessionStore.shared.clear()
            let onboarding = OnboardingViewController()
            let nav = UINavigationController(rootViewController: onboarding)
            window.rootViewController = nav
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }

    static func showNetworkErrorAlert() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
                  let top = topViewController(in: window.rootViewController) else { return }
            let alert = UIAlertController(
                title: "Нет подключения",
                message: "Проверьте подключение к интернету и попробуйте снова.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            top.present(alert, animated: true)
        }
    }

    private static func topViewController(in root: UIViewController?) -> UIViewController? {
        guard let root = root else { return nil }
        if let presented = root.presentedViewController {
            return topViewController(in: presented)
        }
        if let nav = root as? UINavigationController, let visible = nav.visibleViewController {
            return topViewController(in: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(in: selected)
        }
        return root
    }
}
