//
//  CategoryViewController.swift
//  QuizApp
//
//  Created by ebrar seda gündüz on 3.05.2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!

    @IBOutlet weak var sportsButton: UIButton!
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var technologyButton: UIButton!
  
    
    @IBOutlet weak var geographyButton: UIButton!
    var isAdmin = false

    // HomeViewController.swift içine ekleyin

    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
        fetchUserInfo()
    
    }

    @IBAction func leaderboardButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
          if let leaderboardVC = storyboard.instantiateViewController(withIdentifier: "LeaderboardVC") as? LeaderboardViewController {
              navigationController?.pushViewController(leaderboardVC, animated: true)
          }
    }
    
    func setupButtons() {
        configure(button: sportsButton, title: "Sports", imageName: "sports")
        configure(button: historyButton, title: "History", imageName: "history")
        configure(button: technologyButton, title: "Technology", imageName: "technology")
        configure(button: geographyButton, title: "Geography", imageName: "geography")
    }

    func configure(button: UIButton, title: String, imageName: String) {
        button.setBackgroundImage(UIImage(named: imageName), for: .normal)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -60, right: 0)
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
    }

    func fetchUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let nickname = document.data()?["nickname"] as? String ?? "User"
                self.isAdmin = document.data()?["isAdmin"] as? Bool ?? false
                
                DispatchQueue.main.async {
                    self.usernameLabel.text = "👤Hi, \(nickname)"
                    
                                    }
            }
        }
    }
    

    
    @objc func goToAddQuestion() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let addQuestionVC = storyboard.instantiateViewController(withIdentifier: "AddQuestionVC") as? AddQuestionViewController {
            navigationController?.pushViewController(addQuestionVC, animated: true)
        }
    }

    @IBAction func categoryButtonTapped(_ sender: UIButton) {
        guard let category = sender.title(for: .normal) else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let quizVC = storyboard.instantiateViewController(withIdentifier: "QuizVC") as? QuizViewController {
            // Seçilen kategoriyi QuizViewController'a aktar
            quizVC.selectedCategory = category
            
            // QuizViewController'a geçiş yap
            self.navigationController?.pushViewController(quizVC, animated: true)
        } else {
            print("QuizVC bulunamadı veya doğru tipte değil")
        }
    }
}
