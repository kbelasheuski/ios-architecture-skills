import UIKit

final class UserListViewController: UITableViewController {

    private enum Section { case main }

    private let repository: UserRepository
    private(set) var users: [User] = []
    private(set) var page = 0
    private(set) var totalPages = 1
    private(set) var isLoading = false
    private var hasMore: Bool { page < totalPages }
    private var activeLoadID: UUID?
    private var loadTask: Task<Void, Never>?

    private lazy var dataSource: UITableViewDiffableDataSource<Section, User> = {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, user in
            let reusableCell = tableView.dequeueReusableCell(
                withIdentifier: UserCell.reuseID,
                for: indexPath
            )
            guard let cell = reusableCell as? UserCell else {
                return UITableViewCell()
            }
            cell.configure(with: user)
            return cell
        }
    }()

    init(repository: UserRepository) {
        self.repository = repository
        super.init(style: .plain)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Users"
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.reuseID)
        tableView.dataSource = dataSource
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onPull), for: .valueChanged)
        load(reset: true)
    }

    func awaitCurrentLoadForTesting() async {
        await loadTask?.value
    }

    @objc private func onPull() { load(reset: true) }

    private func load(reset: Bool) {
        if !reset, isLoading { return }

        let loadID = UUID()
        activeLoadID = loadID
        isLoading = true
        if reset {
            loadTask?.cancel()
        }

        loadTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if activeLoadID == loadID {
                    isLoading = false
                    activeLoadID = nil
                    refreshControl?.endRefreshing()
                }
            }

            do {
                let target = reset ? 1 : self.page + 1
                let result = try await repository.fetchUsers(page: target)
                try Task.checkCancellation()
                guard activeLoadID == loadID else { return }
                if reset { users = result.users } else { users.append(contentsOf: result.users) }
                page = result.page
                totalPages = result.totalPages
                applySnapshot()
            } catch is CancellationError {
                // swallow
            } catch {
                guard activeLoadID == loadID else { return }
                presentError(error)
            }
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
        snapshot.appendSections([.main])
        snapshot.appendItems(users, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    override func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        let detail = UserDetailViewController(repository: repository, userID: users[indexPath.row].id)
        navigationController?.pushViewController(detail, animated: true)
    }

    override func tableView(_ tv: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard hasMore, !isLoading, indexPath.row >= users.count - 3 else { return }
        load(reset: false)
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "Error",
                                       message: error.localizedDescription,
                                       preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
