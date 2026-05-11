import UIKit
import SafariServices

// MARK: - CalendarViewController
// Figma: calendar.jpg + calendar_event.jpg
// Показывает предстоящие события из Google Calendar сгруппированными по дате.
// Загружает через Backend GET /calendar/events (реализуем вызов через APIClient).

final class CalendarViewController: UIViewController {

    // MARK: - Data

    private struct EventItem {
        let id: String
        let title: String
        let startTime: String   // "HH:mm"
        let endTime: String     // "HH:mm"
        let dateGroup: String   // "26 December"
        let htmlLink: String?
    }

    private var sections: [(date: String, events: [EventItem])] = []
    private var isLoading = false

    // MARK: - UI

    private let headerView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.white
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Календарь"
        l.font = AppFonts.sfProDisplaySemibold(22)
        l.textColor = AppColors.primaryText
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        b.setImage(UIImage(systemName: "xmark", withConfiguration: cfg), for: .normal)
        b.tintColor = AppColors.primaryText
        b.backgroundColor = AppColors.background
        b.layer.cornerRadius = 16
        b.widthAnchor.constraint(equalToConstant: 32).isActive = true
        b.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return b
    }()

    private let tableView: UITableView = {
        let t = UITableView(frame: .zero, style: .plain)
        t.separatorStyle = .none
        t.backgroundColor = AppColors.background
        t.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        return t
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        return s
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Нет предстоящих событий"
        l.font = AppFonts.bodyLarge
        l.textColor = AppColors.secondaryText
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadEvents()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = AppColors.background

        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        view.addSubview(tableView)
        view.addSubview(spinner)
        view.addSubview(emptyLabel)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CalendarEventCell.self, forCellReuseIdentifier: "eventCell")

        [headerView, titleLabel, closeButton, tableView, spinner, emptyLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
    }

    // MARK: - Data loading

    private func loadEvents() {
        guard let user = SessionStore.shared.currentUser else { return }
        isLoading = true
        spinner.startAnimating()
        emptyLabel.isHidden = true

        APIClient.shared.fetchCalendarEvents(user: user) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                self.spinner.stopAnimating()
                switch result {
                case .success(let items):
                    self.sections = self.groupByDate(items)
                    self.tableView.reloadData()
                    self.emptyLabel.isHidden = !self.sections.isEmpty
                case .failure:
                    self.emptyLabel.isHidden = false
                    self.emptyLabel.text = "Не удалось загрузить события"
                }
            }
        }
    }

    // MARK: - Grouping

    private func groupByDate(_ items: [CalendarEventResponse]) -> [(date: String, events: [EventItem])] {
        let iso1 = ISO8601DateFormatter()
        iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]

        func parse(_ s: String?) -> Date? {
            guard let s else { return nil }
            return iso1.date(from: s) ?? iso2.date(from: s)
        }

        let dateFmt = DateFormatter()
        dateFmt.locale = Locale(identifier: "ru_RU")
        dateFmt.dateFormat = "d MMMM"

        let monthFmt = DateFormatter()
        monthFmt.locale = Locale(identifier: "ru_RU")
        monthFmt.dateFormat = "LLLL"

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        var grouped: [(String, [EventItem])] = []
        var dict: [String: [EventItem]] = [:]
        var order: [String] = []

        for item in items {
            guard let start = parse(item.start) else { continue }
            let end = parse(item.end)
            let key = dateFmt.string(from: start)
            let ev = EventItem(
                id: item.id ?? UUID().uuidString,
                title: item.summary ?? "Без названия",
                startTime: timeFmt.string(from: start),
                endTime: end.map { timeFmt.string(from: $0) } ?? "",
                dateGroup: key,
                htmlLink: item.htmlLink
            )
            if dict[key] == nil {
                dict[key] = []
                order.append(key)
            }
            dict[key]?.append(ev)
        }
        return order.compactMap { k in dict[k].map { (k, $0) } }
    }

    // MARK: - Actions

    @objc private func handleClose() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension CalendarViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ev = sections[indexPath.section].events[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as? CalendarEventCell else {
            return UITableViewCell()
        }
        cell.configure(timeRange: "\(ev.startTime)–\(ev.endTime)", title: ev.title)
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].date
    }
}

// MARK: - UITableViewDelegate

extension CalendarViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let ev = sections[indexPath.section].events[indexPath.row]
        guard let link = ev.htmlLink, let url = URL(string: link) else { return }
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = AppFonts.sfProDisplaySemibold(11)
        header.textLabel?.textColor = AppColors.secondaryText
        header.textLabel?.text = header.textLabel?.text?.uppercased()
    }
}

// MARK: - CalendarEventCell
// Figma: белая карточка, "HH:mm–HH:mm" серым, название чёрным

final class CalendarEventCell: UITableViewCell {

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.white
        v.layer.cornerRadius = AppCornerRadius.medium
        AppShadows.small(v)
        return v
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.bodySmall
        l.textColor = AppColors.secondaryText
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = AppFonts.sfProDisplaySemibold(15)
        l.textColor = AppColors.primaryText
        l.numberOfLines = 0
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(timeLabel)
        cardView.addSubview(titleLabel)
        [cardView, timeLabel, titleLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            timeLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            timeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(timeRange: String, title: String) {
        timeLabel.text = timeRange
        titleLabel.text = title
    }
}
