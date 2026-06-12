import UIKit

final class UserListViewController: UITableViewController, UserListViewProtocol {

    var presenter: UserListPresenterProtocol!
    private var rows: [UserListRowEntity] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onPull), for: .valueChanged)
        Task { await presenter.viewDidLoad() }
    }

    @objc private func onPull() {
        Task { await presenter.refresh() }
    }

    func display(rows: [UserListRowEntity]) {
        self.rows = rows
        tableView.reloadData()
    }
    func displayLoading(_ loading: UserListLoading) {
        if loading == .none { refreshControl?.endRefreshing() }
    }
    func displayError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }

    override func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { rows.count }
    override func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: ip)
        var c = cell.defaultContentConfiguration()
        c.text = rows[ip.row].title
        c.secondaryText = rows[ip.row].subtitle
        cell.contentConfiguration = c
        return cell
    }
    override func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        presenter.didSelectRow(at: ip.row)
    }
    override func tableView(_ tv: UITableView, willDisplay cell: UITableViewCell, forRowAt ip: IndexPath) {
        presenter.didDisplayRow(at: ip.row)
    }
}
