import UIKit

class LeaderboardCell: UITableViewCell {
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 25
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.image = UIImage(systemName: "person.fill")
        imageView.tintColor = .systemGray
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let accuracyLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Add subviews
        contentView.addSubview(rankLabel)
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(statsLabel)
        contentView.addSubview(accuracyLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Rank Label
            rankLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rankLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            // User Image
            userImageView.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 12),
            userImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            userImageView.widthAnchor.constraint(equalToConstant: 50),
            userImageView.heightAnchor.constraint(equalToConstant: 50),
            
            // Username Label
            usernameLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 12),
            usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            
            // Stats Label
            statsLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            statsLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            
            // Accuracy Label
            accuracyLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            accuracyLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(with nickname: String, rank: Int, correctAnswers: Int, wrongAnswers: Int, accuracy: Double, photoURL: String?) {
        rankLabel.text = "#\(rank)"
        usernameLabel.text = nickname
        statsLabel.text = "Correct: \(correctAnswers) • Wrong: \(wrongAnswers)"
        accuracyLabel.text = String(format: "%.1f%%", accuracy)
        
        // Set rank color based on position
        switch rank {
        case 1:
            rankLabel.textColor = .systemYellow
        case 2:
            rankLabel.textColor = .systemGray
        case 3:
            rankLabel.textColor = .systemBrown
        default:
            rankLabel.textColor = .darkGray
        }
        
        // Set default image first
        userImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill")
        
        // Load user profile image if available
        if let url = photoURL, let imageURL = URL(string: url) {
            // Here you would use an image loading library like Kingfisher:
            // KingfisherManager.shared.retrieveImage(with: imageURL, options: nil, progressBlock: nil) { result in
            //     switch result {
            //     case .success(let value):
            //         self.userImageView.image = value.image
            //     case .failure:
            //         self.userImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill")
            //     }
            // }
        }
    }
}
