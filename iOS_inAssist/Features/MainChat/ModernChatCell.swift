import UIKit

final class ModernChatCell: UITableViewCell {

    var onOpenLink: ((URL) -> Void)?

    // MARK: - UI Elements

    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = AppCornerRadius.medium
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = AppFonts.bodyMedium
        return label
    }()
    
    private let linkButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        button.setTitle("Open in calendar", for: .normal)
        button.titleLabel?.font = AppFonts.bodySmall
        button.layer.cornerRadius = AppCornerRadius.small
        button.tintColor = .systemBlue
        button.isHidden = true
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.35).cgColor
        return button
    }()
    
    private let actionButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()
    
    private var link: URL?
    private var bubbleLeading: NSLayoutConstraint?
    private var bubbleTrailing: NSLayoutConstraint?
    private var bubbleMaxWidth: NSLayoutConstraint?
    private var linkButtonBottom: NSLayoutConstraint?
    private var bubbleBottomWithLink: NSLayoutConstraint?
    private var bubbleBottomWithoutLink: NSLayoutConstraint?

    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        contentView.addSubview(linkButton)
        contentView.addSubview(actionButtonsStack)
        
        [bubbleView, messageLabel, linkButton, actionButtonsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        bubbleLeading = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        bubbleTrailing = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        let bubbleMaxWidthConstraint = bubbleView.widthAnchor.constraint(lessThanOrEqualToConstant: 280)
        bubbleMaxWidth = bubbleMaxWidthConstraint

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubbleMaxWidthConstraint,

            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 14),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -14),
            
            linkButton.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 8),
            linkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            actionButtonsStack.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 8),
            actionButtonsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            actionButtonsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])

        linkButtonBottom = linkButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        bubbleBottomWithLink = bubbleView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -44)
        bubbleBottomWithoutLink = bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        bubbleBottomWithoutLink?.isActive = true

        linkButton.addTarget(self, action: #selector(handleLinkTap), for: .touchUpInside)
    }
    
    // MARK: - Configure
    
    func configure(with item: ChatItem) {
        link = item.link
        messageLabel.text = item.text

        let isUser = item.sender == .user

        if isUser {
            bubbleView.backgroundColor = AppColors.userBubble
            bubbleView.layer.shadowOpacity = 0
            messageLabel.textColor = AppColors.messageText
            messageLabel.textAlignment = .right
            
            bubbleLeading?.isActive = false
            bubbleTrailing?.isActive = true
            
            linkButton.isHidden = true
            actionButtonsStack.isHidden = true
        } else {
            bubbleView.backgroundColor = AppColors.cardBackground
            bubbleView.layer.shadowColor = UIColor.black.cgColor
            bubbleView.layer.shadowOpacity = 0.06
            bubbleView.layer.shadowOffset = CGSize(width: 0, height: 2)
            bubbleView.layer.shadowRadius = 4
            messageLabel.textColor = AppColors.primaryText
            messageLabel.textAlignment = .left
            
            bubbleLeading?.isActive = true
            bubbleTrailing?.isActive = false

            linkButton.isHidden = item.link == nil

            let showActions = item.text.contains("Would you like") || item.text.contains("Suggestion")
            actionButtonsStack.isHidden = !showActions

            if showActions && actionButtonsStack.arrangedSubviews.isEmpty {
                setupActionButtons()
            }
        }

        if !linkButton.isHidden {
            linkButtonBottom?.isActive = true
            bubbleBottomWithLink?.isActive = true
            bubbleBottomWithoutLink?.isActive = false
        } else if actionButtonsStack.isHidden {
            linkButtonBottom?.isActive = false
            bubbleBottomWithLink?.isActive = false
            bubbleBottomWithoutLink?.isActive = true
        } else {
            linkButtonBottom?.isActive = false
            bubbleBottomWithLink?.isActive = false
            bubbleBottomWithoutLink?.isActive = true
        }
    }
    
    private func setupActionButtons() {
        actionButtonsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let acceptButton = createActionButton(title: "Accept", icon: "checkmark")
        acceptButton.addTarget(self, action: #selector(handleAccept), for: .touchUpInside)

        let editButton = createActionButton(title: "Edit", icon: "pencil")
        editButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)

        let cancelButton = createActionButton(title: "Cancel", icon: "xmark")
        cancelButton.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        
        actionButtonsStack.addArrangedSubview(acceptButton)
        actionButtonsStack.addArrangedSubview(editButton)
        actionButtonsStack.addArrangedSubview(cancelButton)
    }
    
    private func createActionButton(title: String, icon: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = AppColors.cardBackground
        button.layer.cornerRadius = AppCornerRadius.small
        button.tintColor = AppColors.primaryText
        AppShadows.card(button)
        
        var config = UIButton.Configuration.plain()
        config.imagePadding = 4
        config.baseForegroundColor = AppColors.primaryText
        
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        config.image = UIImage(systemName: icon, withConfiguration: iconConfig)
        config.imagePlacement = .trailing
        
        var titleAttr = AttributedString(title)
        titleAttr.font = AppFonts.bodySmall
        config.attributedTitle = titleAttr
        
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        
        button.configuration = config
        
        return button
    }
    
    // MARK: - Actions
    
    @objc private func handleLinkTap() {
        guard let link else { return }
        onOpenLink?(link)
    }

    @objc private func handleAccept() {
    }

    @objc private func handleEdit() {
    }

    @objc private func handleCancel() {
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        link = nil
        messageLabel.text = nil
        linkButton.isHidden = true
        actionButtonsStack.isHidden = true
        bubbleView.layer.shadowOpacity = 0
        bubbleLeading?.isActive = false
        bubbleTrailing?.isActive = false
        linkButtonBottom?.isActive = false
        bubbleBottomWithLink?.isActive = false
        bubbleBottomWithoutLink?.isActive = false
    }
}
