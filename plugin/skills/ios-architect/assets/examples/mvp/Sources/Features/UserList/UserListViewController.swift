import UIKit

final class UserListViewController: UITableViewController, UserListView {

    var presenter: UserListPresenting!
    private var rows: [UserListRowViewModel] = []

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

    func display(rows: [UserListRowViewModel]) {
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

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = rows[indexPath.row].title
        config.secondaryText = rows[indexPath.row].subtitle
        cell.contentConfiguration = config
        return cell
    }
    override func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        presenter.didSelectRow(at: indexPath.row)
    }
    override func tableView(_ tv: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        presenter.didDisplayRow(at: indexPath.row)
    }
}
