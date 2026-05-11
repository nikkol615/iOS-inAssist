import UIKit

// MARK: - EventPreviewCardCell
// Figma: evet.jpg — блок ответа ассистента с предложением события.
// Структура: текст ассистента + "Event sub-card:" + emoji-строки + кнопки Accept/Edit/Cancel

final class EventPreviewCardCell: UITableViewCell {

    var onConfirm: (() -> Void)?
    var onEdit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    // MARK: - UI

    private let bubbleView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.white
        v.layer.cornerRadius = AppCornerRadius.medium
        AppShadows.small(v)
        return v
    }()

    private let assistantTextLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodyMedium
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    private let subCardLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodySmall
        l.textColor = AppColors.secondaryText
        l.text = "Event sub-card:"
        return l
    }()

    private let suggestionLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodyMedium
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodyMedium
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    private let acceptButton = EventPreviewCardCell._actionBtn(title: "Accept", icon: "checkmark")
    private let editButton   = EventPreviewCardCell._actionBtn(title: "Edit",   icon: "pencil")
    private let cancelButton = EventPreviewCardCell._actionBtn(title: "Cancel", icon: "xmark")

    private let buttonsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        return s
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(bubbleView)
        [assistantTextLabel, subCardLabel, suggestionLabel, timeLabel].forEach {
            bubbleView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        bubbleView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(buttonsStack)
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        [acceptButton, editButton, cancelButton].forEach { buttonsStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 300),

            assistantTextLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 14),
            assistantTextLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            assistantTextLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),

            subCardLabel.topAnchor.constraint(equalTo: assistantTextLabel.bottomAnchor, constant: 10),
            subCardLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            subCardLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),

            suggestionLabel.topAnchor.constraint(equalTo: subCardLabel.bottomAnchor, constant: 4),
            suggestionLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            suggestionLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),

            timeLabel.topAnchor.constraint(equalTo: suggestionLabel.bottomAnchor, constant: 2),
            timeLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            timeLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -14),

            buttonsStack.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 8),
            buttonsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])

        acceptButton.addTarget(self, action: #selector(didTapAccept), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(didTapEdit),   for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(with item: ChatItem) {
        assistantTextLabel.text = item.text

        let suggestion = item.eventStart != nil ? (item.text.isEmpty ? "free hour" : item.text) : "—"
        suggestionLabel.text = "📅 Suggestion: \(suggestion)"

        if let start = item.eventStart, let end = item.eventEnd {
            timeLabel.text = "⏰ Time: \(_formatTimeRange(start: start, end: end))"
        } else {
            timeLabel.text = nil
        }
    }

    // MARK: - Actions

    @objc private func didTapAccept() { onConfirm?() }
    @objc private func didTapEdit()   { onEdit?("Измени: ") }
    @objc private func didTapCancel() { onCancel?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        assistantTextLabel.text = nil
        suggestionLabel.text = nil
        timeLabel.text = nil
    }

    // MARK: - Helpers

    private func _formatTimeRange(start: String, end: String) -> String {
        let iso1 = ISO8601DateFormatter()
        iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]

        func parse(_ s: String) -> Date? { iso1.date(from: s) ?? iso2.date(from: s) }

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ru_RU")
        fmt.dateFormat = "HH:mm"

        guard let s = parse(start) else { return "\(start)–\(end)" }
        let endStr = parse(end).map { fmt.string(from: $0) } ?? end
        return "\(fmt.string(from: s))–\(endStr)"
    }

    private static func _actionBtn(title: String, icon: String) -> UIButton {
        let b = UIButton(type: .system)
        b.backgroundColor = AppColors.white
        b.layer.cornerRadius = AppCornerRadius.small
        b.layer.borderWidth = 1
        b.layer.borderColor = AppColors.divider.cgColor
        b.tintColor = AppColors.primaryText

        var cfg = UIButton.Configuration.plain()
        cfg.imagePadding = 4
        cfg.baseForegroundColor = AppColors.primaryText
        let sym = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        cfg.image = UIImage(systemName: icon, withConfiguration: sym)
        cfg.imagePlacement = .trailing
        var t = AttributedString(title)
        t.font = AppFonts.bodySmall
        cfg.attributedTitle = t
        cfg.contentInsets = .init(top: 8, leading: 12, bottom: 8, trailing: 12)
        b.configuration = cfg
        AppShadows.small(b)
        return b
    }
}
