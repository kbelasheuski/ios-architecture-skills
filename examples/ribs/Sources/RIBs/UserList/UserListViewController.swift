import RIBs
import UIKit

public final class UserListViewController:
    UIViewController,
    UserListPresentable,
    UserListViewControllable,
    UITableViewDataSource, UITableViewDelegate {
    public weak var listener: UserListPresentableListener?

    private let tableView = UITableView()
    private let refresh = UIRefreshControl()
    private var rows: [UserListRow] = []

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.refreshControl = refresh
        refresh.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
    }

    @objc private func onRefresh() { listener?.refresh() }

    public func display(rows: [UserListRow]) {
        self.rows = rows
        tableView.reloadData()
    }

    public func display(loading: UserListLoading) {
        if loading == .none { refresh.endRefreshing() }
    }

    public func displayError(_ message: String) {
        let a = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        a.addAction(.init(title: "OK", style: .default))
        present(a, animated: true)
    }

    public func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { rows.count }
    public func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: ip)
        var c = cell.defaultContentConfiguration()
        c.text = rows[ip.row].title
        c.secondaryText = rows[ip.row].subtitle
        cell.contentConfiguration = c
        return cell
    }
    public func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        listener?.didSelectRow(at: ip.row)
    }
    public func tableView(_ tv: UITableView, willDisplay cell: UITableViewCell, forRowAt ip: IndexPath) {
        listener?.didDisplayRow(at: ip.row)
    }
}
