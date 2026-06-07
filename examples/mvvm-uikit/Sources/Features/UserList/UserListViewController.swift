import Combine
import UIKit

final class UserListViewController: UITableViewController {

    private let viewModel: UserListViewModel
    private var cancellables: Set<AnyCancellable> = []

    init(viewModel: UserListViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onPull), for: .valueChanged)
        bind()
        viewModel.onAppear()
    }

    private func bind() {
        viewModel.$users
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.tableView.reloadData() }
            .store(in: &cancellables)

        viewModel.$loading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if state == .none { self?.refreshControl?.endRefreshing() }
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in self?.presentError(msg) }
            .store(in: &cancellables)
    }

    private func presentError(_ msg: String) {
        let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default) { [weak self] _ in self?.viewModel.dismissError() })
        present(alert, animated: true)
    }

    @objc private func onPull() { viewModel.refresh() }

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.users.count
    }
    override func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: ip)
        var content = cell.defaultContentConfiguration()
        content.text = viewModel.users[ip.row].name
        content.secondaryText = viewModel.users[ip.row].email
        cell.contentConfiguration = content
        return cell
    }
    override func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        viewModel.didSelectRow(at: ip.row)
    }
    override func tableView(_ tv: UITableView, willDisplay cell: UITableViewCell, forRowAt ip: IndexPath) {
        viewModel.didDisplayRow(at: ip.row)
    }
}
