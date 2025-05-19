import UIKit
import FirebaseFirestore
import FirebaseAuth

class LeaderboardViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
   
    @IBOutlet weak var titleLabel: UILabel!

    // Podium Outlets
    @IBOutlet weak var firstUserImageView: UIImageView!
    @IBOutlet weak var firstUserNameLabel: UILabel!
    @IBOutlet weak var firstUserScoreLabel: UILabel!
    @IBOutlet weak var secondUserImageView: UIImageView!
    @IBOutlet weak var secondUserNameLabel: UILabel!
    @IBOutlet weak var secondUserScoreLabel: UILabel!
    @IBOutlet weak var thirdUserImageView: UIImageView!
    @IBOutlet weak var thirdUserNameLabel: UILabel!
    @IBOutlet weak var thirdUserScoreLabel: UILabel!

    // Crown and Rank Labels (Now using labels directly as badges)
    @IBOutlet weak var firstUserCrownImageView: UIImageView! // Taç için
    @IBOutlet weak var firstUserRankLabel: UILabel! // Bu label'ı storyboard'da gizleyip sadece tacı göstereceğiz
    @IBOutlet weak var secondUserRankLabel: UILabel! // 2. sıra badge label'ı
    @IBOutlet weak var thirdUserRankLabel: UILabel! // 3. sıra badge label'ı

    // Rank Badge Views - Bunlara artık gerek yok, istersen silebilirsin.
    // @IBOutlet weak var secondRankBadgeView: UIView!
    // @IBOutlet weak var thirdRankBadgeView: UIView!


    private var users: [(nickname: String, correctAnswers: Int, wrongAnswers: Int, totalAnswers: Int, accuracy: Double, photoURL: String?)] = []
    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchLeaderboardData()
    }

    private func setupUI() {
        title = "Leaderboard"
        titleLabel.text = "🏆Leaderboard"
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LeaderboardCell.self, forCellReuseIdentifier: "LeaderboardCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        // Setup podium user images (Round corners are still here)
        firstUserImageView.layer.cornerRadius = firstUserImageView.frame.width / 2
        firstUserImageView.clipsToBounds = true
        secondUserImageView.layer.cornerRadius = secondUserImageView.frame.width / 2
        secondUserImageView.clipsToBounds = true
        thirdUserImageView.layer.cornerRadius = thirdUserImageView.frame.width / 2
        thirdUserImageView.clipsToBounds = true

        // Setup rank badge labels (Make them circular and style them)
        // Ensure the labels are square in Storyboard constraints for this to work correctly.
        secondUserRankLabel.layer.cornerRadius = secondUserRankLabel.frame.width / 2
        secondUserRankLabel.clipsToBounds = true
        secondUserRankLabel.backgroundColor = .darkGray // Badge arka plan rengi
        secondUserRankLabel.textColor = .white // Badge yazı rengi
        secondUserRankLabel.textAlignment = .center
        secondUserRankLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold) // Font boyutunu ayarla

        thirdUserRankLabel.layer.cornerRadius = thirdUserRankLabel.frame.width / 2
        thirdUserRankLabel.clipsToBounds = true
        thirdUserRankLabel.backgroundColor = .darkGray // Badge arka plan rengi
        thirdUserRankLabel.textColor = .white // Badge yazı rengi
        thirdUserRankLabel.textAlignment = .center
        thirdUserRankLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold) // Font boyutunu ayarla


        // Add background color
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
    }

    private func fetchLeaderboardData() {
       

        // Önce kullanıcının giriş yapmış olduğundan emin olalım
        guard Auth.auth().currentUser != nil else {
            showError(message: "Please login to view the leaderboard")
            return
        }

        db.collection("users")
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    

                    if let error = error {
                        print("Error fetching leaderboard data: \(error)")
                        self.showError(message: "Failed to load leaderboard data. Please try again.")
                        return
                    }

                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        self.showError(message: "No users found in the leaderboard")
                        return
                    }

                    // Tüm kullanıcıları al ve filtrele
                    self.users = documents.compactMap { document -> (nickname: String, correctAnswers: Int, wrongAnswers: Int, totalAnswers: Int, accuracy: Double, photoURL: String?)? in
                        let data = document.data()
                        if let isAdmin = data["isAdmin"] as? Bool, isAdmin { return nil }

                        // Make sure to safely unwrap the values
                        guard let nickname = data["nickname"] as? String else { return nil }

                        // Default to 0 if values are missing
                        let correctAnswers = data["correctAnswers"] as? Int ?? 0
                        let wrongAnswers = data["wrongAnswers"] as? Int ?? 0

                        let totalAnswers = correctAnswers + wrongAnswers
                        let accuracy = totalAnswers > 0 ? Double(correctAnswers) / Double(totalAnswers) * 100 : 0
                        let photoURL = data["photoURL"] as? String

                        return (nickname, correctAnswers, wrongAnswers, totalAnswers, accuracy, photoURL)
                    }

                    // Kullanıcıları doğruluk oranına göre sırala (en yüksekten en düşüğe)
                    self.users.sort { (user1, user2) -> Bool in
                        if user1.accuracy == user2.accuracy {
                            return user1.correctAnswers > user2.correctAnswers
                        }
                        return user1.accuracy > user2.accuracy
                    }

                    // Update podium with top 3 users
                    self.updatePodium()

                    // Reload table view to display remaining users
                    self.tableView.reloadData()
                }
            }
    }

    private func updatePodium() {
        let podium = Array(users.prefix(3))

        // Reset all podium elements to hidden or default state
        firstUserNameLabel.text = "---"
        firstUserScoreLabel.text = "---"
        firstUserCrownImageView.isHidden = true // Hide crown by default
        firstUserImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill") // Placeholder
        firstUserImageView.layer.borderColor = UIColor.clear.cgColor // Clear border by default
        firstUserImageView.layer.borderWidth = 0 // No border by default
        firstUserRankLabel.isHidden = true // Hide 1st rank label label


        secondUserNameLabel.text = "---"
        secondUserScoreLabel.text = "---"
        secondUserRankLabel.isHidden = true // Hide 2nd rank label/badge by default
        secondUserImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill") // Placeholder
        secondUserImageView.layer.borderColor = UIColor.clear.cgColor // Clear border by default
        secondUserImageView.layer.borderWidth = 0 // No border by default


        thirdUserNameLabel.text = "---"
        thirdUserScoreLabel.text = "---"
        thirdUserRankLabel.isHidden = true // Hide 3rd rank label/badge by default
        thirdUserImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill") // Placeholder
        thirdUserImageView.layer.borderColor = UIColor.clear.cgColor // Clear border by default
        thirdUserImageView.layer.borderWidth = 0 // No border by default


        // 1. kullanıcı (Index 0)
        if podium.indices.contains(0) {
            let user = podium[0]
            firstUserNameLabel.text = user.nickname
            firstUserScoreLabel.text = String(format: "%.3f", user.accuracy) // Accuracy format changed based on image
            firstUserCrownImageView.image = UIImage(systemName: "crown.fill") // SF Symbol taç!
            firstUserCrownImageView.tintColor = .systemYellow // Rengini sarı yap
            firstUserCrownImageView.isHidden = false // Show crown

            // Add yellow border to 1st user's image
            firstUserImageView.layer.borderColor = UIColor.systemYellow.cgColor
            firstUserImageView.layer.borderWidth = 3 // Adjust border width as needed

            // Load profile photo (using placeholder for now, integrate Kingfisher later)
            if let url = user.photoURL, let imageURL = URL(string: url) {
                 // Kingfisher usage here to load image asynchronously
                 // KingfisherManager.shared.retrieveImage(with: imageURL, options: nil, progressBlock: nil) { result in
                 //     switch result {
                 //     case .success(let value):
                 //         self.firstUserImageView.image = value.image
                 //     case .failure:
                 //         self.firstUserImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill")
                 //     }
                 // }
                 self.firstUserImageView.image = UIImage(systemName: "person.fill") // Using SF Symbol as placeholder
             } else {
                 firstUserImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill")
             }
        }

        // 2. kullanıcı (Index 1)
        if podium.indices.contains(1) {
            let user = podium[1]
            secondUserNameLabel.text = user.nickname
            secondUserScoreLabel.text = String(format: "%.3f", user.accuracy) // Accuracy format changed based on image

            // Show and configure 2nd rank label as badge
            secondUserRankLabel.isHidden = false
            secondUserRankLabel.text = "2"
             // Colors and alignment already set in setupUI
             // secondUserRankLabel.textColor = .white
             // secondUserRankLabel.backgroundColor = .darkGray


            // Load profile photo
            if let url = user.photoURL, let imageURL = URL(string: url) {
                 self.secondUserImageView.image = UIImage(systemName: "person.fill") // Using SF Symbol as placeholder
             } else {
                 secondUserImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill")
             }

             // Optional: Add a subtle border to 2nd user image
             // secondUserImageView.layer.borderColor = UIColor.gray.cgColor
             // secondUserImageView.layer.borderWidth = 1
        }

        // 3. kullanıcı (Index 2)
        if podium.indices.contains(2) {
            let user = podium[2]
            thirdUserNameLabel.text = user.nickname
            thirdUserScoreLabel.text = String(format: "%.3f", user.accuracy) // Accuracy format changed based on image

            // Show and configure 3rd rank label as badge
            thirdUserRankLabel.isHidden = false
            thirdUserRankLabel.text = "3"
             // Colors and alignment already set in setupUI
             // thirdUserRankLabel.textColor = .white
             // thirdUserRankLabel.backgroundColor = .darkGray

            // Load profile photo
            if let url = user.photoURL, let imageURL = URL(string: url) {
                 self.thirdUserImageView.image = UIImage(systemName: "person.fill") // Using SF Symbol as placeholder
             } else {
                 thirdUserImageView.image = UIImage(named: "default_avatar") ?? UIImage(systemName: "person.fill")
             }

             // Optional: Add a subtle border to 3rd user image
             // thirdUserImageView.layer.borderColor = UIColor.gray.cgColor
             // thirdUserImageView.layer.borderWidth = 1
        }

        // For remaining users in the table view, update the cell configuration.
        // The current configure method already handles rank starting from 4.
        // Ensure the LeaderboardCell has UI elements for rank, photo, name, and score.
    }


    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension LeaderboardViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the count of users *after* the top 3
        return max(users.count - 3, 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LeaderboardCell", for: indexPath) as! LeaderboardCell

        // Make sure we're not out of bounds and access the correct user (index 3 onwards)
        if indexPath.row + 3 < users.count {
            let user = users[indexPath.row + 3]
             // Pass rank as indexPath.row + 4 (since index 0 in tableView is rank 4)
            cell.configure(with: user.nickname, rank: indexPath.row + 4, correctAnswers: user.correctAnswers, wrongAnswers: user.wrongAnswers, accuracy: user.accuracy, photoURL: user.photoURL)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
