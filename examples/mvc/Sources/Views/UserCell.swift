import UIKit

final class UserCell: UITableViewCell {
    static let reuseID = "UserCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with user: User) {
        var config = defaultContentConfiguration()
        config.text = user.name
        config.secondaryText = user.email
        contentConfiguration = config
    }
}
