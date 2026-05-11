import UIKit

extension UIColor {
    convenience init?(hex: String, alpha: CGFloat = 1.0) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }
        guard hexSanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    /// Returns the color for the given hex string, or a fallback if parsing fails.
    static func hex(_ string: String, alpha: CGFloat = 1.0, default fallback: UIColor = .black) -> UIColor {
        UIColor(hex: string, alpha: alpha) ?? fallback
    }
}

// MARK: - Design System Colors

enum AppColors {
    // Figma: чистый светло-серый фон #F2F2F7 (iOS grouped background)
    static let background = UIColor.hex("#F2F2F7", default: UIColor(red: 0.949, green: 0.949, blue: 0.969, alpha: 1))
    static let white = UIColor.white
    static let black = UIColor.hex("#1A1A1A")

    static let primaryText = UIColor.hex("#1A1A1A")
    static let secondaryText = UIColor.hex("#8E8E93")
    static let messageText = UIColor.hex("#3C3C43")

    static let userBubble = UIColor.hex("#EBEBEB")
    static let cardBackground = UIColor.white
    static let buttonBackground = UIColor.hex("#1A1A1A")
    static let buttonBorder = UIColor.hex("#3A3A3A")
    static let divider = UIColor.hex("#E5E5EA")
    static let inputBorder = UIColor.hex("#E5E5EA")
    static let chipBackground = UIColor.hex("#EBEBEB")

    // Figma: акцентный синий (кнопки Continue, Join meet, mic)
    static let accentBlue = UIColor.hex("#5B7BFF", default: .systemBlue)
    // Google Blue для mic иконки
    static let googleBlue = UIColor.hex("#4285F4", default: .systemBlue)
}

// MARK: - Design System Fonts

enum AppFonts {
    static func sfProDisplaySemibold(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .semibold)
    }
    static func sfProDisplayMedium(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .medium)
    }
    static func sfProDisplayRegular(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .regular)
    }
    static func sfProDisplayBold(_ size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size, weight: .bold)
    }

    static let titleLarge = sfProDisplaySemibold(28)
    static let titleMedium = sfProDisplaySemibold(24)
    static let titleSmall = sfProDisplaySemibold(16)
    static let bodyLarge = sfProDisplayRegular(16)
    static let bodyMedium = sfProDisplayRegular(14)
    static let bodySmall = sfProDisplayRegular(12)
    static let button = sfProDisplayMedium(16)
}

// MARK: - Design System Shadows

enum AppShadows {
    static func card(_ view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 16
    }
    static func small(_ view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.06
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4.5
    }
    static func button(_ view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 11
    }
}

// MARK: - Design System Corner Radius

enum AppCornerRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 16
    static let large: CGFloat = 18
    static let extraLarge: CGFloat = 24
    static let round: CGFloat = 99
}
