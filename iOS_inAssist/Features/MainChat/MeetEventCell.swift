import UIKit
import SafariServices

// MARK: - MeetEventCell
// Figma: meet.jpg — карточка подтверждённого события в чате.
// Показывает полную информацию: название, описание, дату/время, напоминание,
// участников, формат, ссылку на конференцию и кнопку "Join meet".

final class MeetEventCell: UITableViewCell {

    var onJoinMeet: ((URL) -> Void)?
    var onOpenCalendar: ((URL) -> Void)?

    // MARK: - UI

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.white
        v.layer.cornerRadius = AppCornerRadius.medium
        AppShadows.card(v)
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.sfProDisplaySemibold(17)
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    private let descriptionLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodyMedium
        l.textColor = AppColors.secondaryText
        l.numberOfLines = 0
        return l
    }()

    private let dateTimeSectionLabel = MeetEventCell._sectionLabel("Date and time")
    private let dateTimeLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodyMedium
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    private let participantsSectionLabel = MeetEventCell._sectionLabel("Participants")
    private let participantsLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodyMedium
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    private let locationSectionLabel = MeetEventCell._sectionLabel("Location")
    private let locationLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodyMedium
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    private let conferenceLinkContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.background
        v.layer.cornerRadius = AppCornerRadius.small
        v.layer.borderWidth = 1
        v.layer.borderColor = AppColors.divider.cgColor
        return v
    }()

    private let conferenceLinkLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodySmall
        l.textColor = AppColors.secondaryText
        l.text = "Conference link"
        return l
    }()

    private let conferenceLinkValueLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodyMedium
        l.textColor = AppColors.accentBlue
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingMiddle
        return l
    }()

    private let copyButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        b.setImage(UIImage(systemName: "doc.on.doc", withConfiguration: cfg), for: .normal)
        b.tintColor = AppColors.secondaryText
        return b
    }()

    private let joinMeetButton: UIButton = {
        let b = UIButton(type: .system)
        b.backgroundColor = AppColors.accentBlue
        b.layer.cornerRadius = AppCornerRadius.large
        b.setTitle("Join meet", for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = AppFonts.button
        AppShadows.button(b)
        return b
    }()

    // Separator views
    private let sep1 = MeetEventCell._separator()
    private let sep2 = MeetEventCell._separator()
    private let sep3 = MeetEventCell._separator()

    private var conferenceURL: URL?

    // MARK: - Stack view for content

    private lazy var contentStack: UIStackView = {
        let s = UIStackView(arrangedSubviews: [
            titleLabel,
            descriptionLabel,
            sep1,
            dateTimeSectionLabel,
            dateTimeLabel,
            sep2,
            participantsSectionLabel,
            participantsLabel,
            sep3,
            locationSectionLabel,
            locationLabel,
            conferenceLinkContainer,
            joinMeetButton,
        ])
        s.axis = .vertical
        s.spacing = 8
        s.setCustomSpacing(4, after: dateTimeSectionLabel)
        s.setCustomSpacing(4, after: participantsSectionLabel)
        s.setCustomSpacing(4, after: locationSectionLabel)
        s.setCustomSpacing(12, after: sep1)
        s.setCustomSpacing(12, after: sep2)
        s.setCustomSpacing(12, after: sep3)
        s.setCustomSpacing(12, after: conferenceLinkContainer)
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

        contentView.addSubview(cardView)
        cardView.addSubview(contentStack)

        // Conference link subviews
        [conferenceLinkLabel, conferenceLinkValueLabel, copyButton].forEach {
            conferenceLinkContainer.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [cardView, contentStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            // Conference link layout
            conferenceLinkLabel.topAnchor.constraint(equalTo: conferenceLinkContainer.topAnchor, constant: 8),
            conferenceLinkLabel.leadingAnchor.constraint(equalTo: conferenceLinkContainer.leadingAnchor, constant: 12),
            conferenceLinkLabel.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -8),

            conferenceLinkValueLabel.topAnchor.constraint(equalTo: conferenceLinkLabel.bottomAnchor, constant: 2),
            conferenceLinkValueLabel.leadingAnchor.constraint(equalTo: conferenceLinkContainer.leadingAnchor, constant: 12),
            conferenceLinkValueLabel.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -8),
            conferenceLinkValueLabel.bottomAnchor.constraint(equalTo: conferenceLinkContainer.bottomAnchor, constant: -8),

            copyButton.trailingAnchor.constraint(equalTo: conferenceLinkContainer.trailingAnchor, constant: -12),
            copyButton.centerYAnchor.constraint(equalTo: conferenceLinkContainer.centerYAnchor),
            copyButton.widthAnchor.constraint(equalToConstant: 28),
            copyButton.heightAnchor.constraint(equalToConstant: 28),

            joinMeetButton.heightAnchor.constraint(equalToConstant: 50),
        ])

        joinMeetButton.addTarget(self, action: #selector(didTapJoin), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(didTapCopy), for: .touchUpInside)
    }

    // MARK: - Configure

    func configure(with item: ChatItem) {
        titleLabel.text = item.text

        // Description
        let hasDesc = !(item.eventDescription ?? "").isEmpty
        descriptionLabel.text = item.eventDescription
        descriptionLabel.isHidden = !hasDesc

        // Date/time
        if let start = item.eventStart {
            let timeStr = _formatDateTime(start: start, end: item.eventEnd)
            dateTimeLabel.text = "📅 \(timeStr)\n⏰ Reminder 1 hour before"
        } else {
            dateTimeLabel.text = nil
        }
        [sep1, dateTimeSectionLabel, dateTimeLabel].forEach { $0.isHidden = item.eventStart == nil }

        // Location / participants — not in ChatItem yet, hide
        [sep2, participantsSectionLabel, participantsLabel].forEach { $0.isHidden = true }
        [sep3, locationSectionLabel, locationLabel].forEach { $0.isHidden = true }

        // Conference link — show if we have htmlLink
        let hasLink = item.link != nil
        conferenceLinkContainer.isHidden = !hasLink
        joinMeetButton.isHidden = !hasLink
        if let url = item.link {
            conferenceURL = url
            conferenceLinkValueLabel.text = url.absoluteString
        }
    }

    // MARK: - Actions

    @objc private func didTapJoin() {
        guard let url = conferenceURL else { return }
        onJoinMeet?(url)
    }

    @objc private func didTapCopy() {
        UIPasteboard.general.string = conferenceURL?.absoluteString
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        descriptionLabel.text = nil
        dateTimeLabel.text = nil
        conferenceURL = nil
        conferenceLinkValueLabel.text = nil
    }

    // MARK: - Helpers

    private func _formatDateTime(start: String, end: String?) -> String {
        let iso1 = ISO8601DateFormatter()
        iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]

        func parse(_ s: String) -> Date? { iso1.date(from: s) ?? iso2.date(from: s) }

        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "ru_RU")
        dateFmt.dateFormat = "d MMMM"

        let timeFmt = DateFormatter()
        timeFmt.locale = Locale(identifier: "ru_RU")
        timeFmt.dateFormat = "HH:mm"

        guard let s = parse(start) else { return start }
        let dateStr = dateFmt.string(from: s)
        let startTime = timeFmt.string(from: s)
        if let e = end.flatMap({ parse($0) }) {
            return "\(dateStr), \(startTime)–\(timeFmt.string(from: e))"
        }
        return "\(dateStr), \(startTime)"
    }

    private static func _sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = AppFonts.bodySmall
        l.textColor = AppColors.secondaryText
        return l
    }

    private static func _separator() -> UIView {
        let v = UIView()
        v.backgroundColor = AppColors.divider
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }
}
