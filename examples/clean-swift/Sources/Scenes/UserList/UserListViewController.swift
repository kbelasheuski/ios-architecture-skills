import UIKit

@MainActor
public protocol UserListDisplayLogic: AnyObject {
    func display(_ viewModel: UserList.FetchUsers.ViewModel)
}

final class UserListViewController: UITableViewController, UserListDisplayLogic {

    var interactor: UserListBusinessLogic!
    var router: (UserListRoutingLogic & UserListDataPassing)!
    private var rows: [UserList.FetchUsers.ViewModel.Row] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onPull), for: .valueChanged)
        Task { await interactor.fetchUsers(.init(reset: true)) }
    }

    @objc private func onPull() {
        Task { await interactor.fetchUsers(.init(reset: true)) }
    }

    func display(_ viewModel: UserList.FetchUsers.ViewModel) {
        rows = viewModel.rows
        tableView.reloadData()
        if viewModel.loading == .none { refreshControl?.endRefreshing() }
        if let msg = viewModel.errorMessage {
            let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }
    override func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: ip)
        var content = cell.defaultContentConfiguration()
        content.text = rows[ip.row].title
        content.secondaryText = rows[ip.row].subtitle
        cell.contentConfiguration = content
        return cell
    }
    override func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        interactor.selectRow(.init(index: ip.row))
        router.routeToDetail()
    }
    override func tableView(_ tv: UITableView, willDisplay cell: UITableViewCell, forRowAt ip: IndexPath) {
        if ip.row >= rows.count - 3 {
            Task { await interactor.fetchUsers(.init(reset: false)) }
        }
    }
}
