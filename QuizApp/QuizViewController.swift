//
//  QuizViewController.swift
//  QuizApp
//
//  Created by ebrar seda gündüz on 3.05.2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class QuizViewController: UIViewController {

    // UI Elements from first code
    @IBOutlet weak var timerCircleView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var questionCountLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var optionButton1: UIButton!
    @IBOutlet weak var optionButton2: UIButton!
    @IBOutlet weak var optionButton3: UIButton!
    @IBOutlet weak var optionButton4: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var timerCircleLayer: CAShapeLayer?
    
    // Variables from second code
    var questions: [(question: String, options: [String], correctAnswer: String)] = []
    var currentQuestionIndex = 0
    var timer: Timer?
    var timeLeft = 10
    var correctCount = 0
    var wrongCount = 0
    var isAlertPresenting = false
    var selectedCategory: String?
    var questionsLimit = 20 // Maksimum soru sayısı sınırı

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        guard let user = Auth.auth().currentUser else {
            print("Kullanıcı giriş yapmamış. Ana ekrana dönülüyor.")
            navigationController?.popToRootViewController(animated: true)
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), let isAdmin = data["isAdmin"] as? Bool, isAdmin {
                print("Bu kullanıcı bir admin.")
            } else {
                print("Normal kullanıcı, quiz başlatılıyor.")
            }
            
            self.loadQuestionsForSelectedCategory()
        }
    }
    
    func setupUI() {
        // Soru label ayarları
        questionLabel.textColor = .black
        questionLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        questionLabel.numberOfLines = 0
        questionLabel.textAlignment = .center
        questionLabel.lineBreakMode = .byWordWrapping
        questionLabel.adjustsFontSizeToFitWidth = true
        questionLabel.minimumScaleFactor = 0.8

        
        // Timer circle view ayarları
        timerCircleView.backgroundColor = .clear
        timerLabel.textColor = .black
        timerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        
        // Butonlar için ayarlar
        let buttons = [optionButton1, optionButton2, optionButton3, optionButton4]
        for button in buttons {
            button?.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            button?.layer.cornerRadius = 28
            button?.setTitleColor(.white, for: .normal)
            button?.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button?.contentHorizontalAlignment = .left
            button?.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
            button?.isEnabled = true
            button?.isSelected = false
            button?.layer.borderWidth = 0
            button?.layer.borderColor = nil
        }
        
        // Next button ayarları
        nextButton.backgroundColor = UIColor(red: 104/255, green: 195/255, blue: 225/255, alpha: 1.0)
        nextButton.layer.cornerRadius = 28
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        nextButton.isHidden = true
        nextButton.isEnabled = true
        nextButton.isSelected = false
        
        // Progress bar ayarları
        progressBar.progressTintColor = UIColor(red: 255/255, green: 179/255, blue: 71/255, alpha: 1.0)
        progressBar.trackTintColor = UIColor(white: 1.0, alpha: 0.3)
        
        // Timer circle oluştur
        setupTimerCircle()
        view.bringSubviewToFront(nextButton)
    }
    
    func setupTimerCircle() {
        timerCircleLayer?.removeFromSuperlayer()
        
        let center = CGPoint(x: timerCircleView.bounds.midX, y: timerCircleView.bounds.midY)
        let radius = min(timerCircleView.bounds.width, timerCircleView.bounds.height) / 2 - 5
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let circularPath = UIBezierPath(arcCenter: center,
                                      radius: radius,
                                      startAngle: startAngle,
                                      endAngle: endAngle,
                                      clockwise: true)
        
        // Background track layer
        let trackLayer = CAShapeLayer()
        trackLayer.path = circularPath.cgPath
        trackLayer.strokeColor = UIColor(white: 1.0, alpha: 0.2).cgColor
        trackLayer.lineWidth = 8
        trackLayer.fillColor = UIColor.clear.cgColor
        timerCircleView.layer.addSublayer(trackLayer)
        
        // Progress layer
        let progressLayer = CAShapeLayer()
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = UIColor(red: 104/255, green: 195/255, blue: 225/255, alpha: 1.0).cgColor
        progressLayer.lineWidth = 8
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1.0
        
        timerCircleView.layer.addSublayer(progressLayer)
        timerCircleLayer = progressLayer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupTimerCircle()
    }
    func loadQuestionsForSelectedCategory() {
        guard let selectedCategory = selectedCategory else {
            print("Kategori seçilmemiş!")
            return
        }
        
        let db = Firestore.firestore()
        print("Kategori sorgusu başlatılıyor: \(selectedCategory)")
        
        // Kategoriye göre filtreleme yaparken case-insensitive karşılaştırma
        db.collection("questions")
            .whereField("category", isEqualTo: selectedCategory) // Firestore'da case-sensitive arama
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching questions: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    self.showNoQuestionsAlert()
                    return
                }
                
                print("Toplam döküman sayısı: \(documents.count)")
                
                self.questions = documents.compactMap { doc -> (String, [String], String)? in
                    let data = doc.data()
                    print("Değerlendirilen soru: \(data["question"] ?? "N/A")")
                    
                    // Firestore'daki alan isimlerini kontrol edin (correctAnswer veya correctOption)
                    guard let question = data["question"] as? String,
                          let options = data["options"] as? [String],
                          let correctAnswer = data["correctAnswer"] as? String ?? data["correctOption"] as? String else {
                        print("Invalid question format: \(data)")
                        return nil
                    }
                    
                    return (question, options, correctAnswer)
                }
                
                // Soruları karıştır
                self.questions.shuffle()
                
                print("Kategori için yüklenen soru sayısı: \(self.questions.count)")
                
                DispatchQueue.main.async {
                    if self.questions.isEmpty {
                        self.showNoQuestionsAlert()
                    } else {
                        self.loadQuestion()
                    }
                }
            }
    }

    func resetAllButtons() {
        let buttons = [optionButton1, optionButton2, optionButton3, optionButton4]
        for button in buttons {
            button?.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            button?.setTitleColor(.white, for: .normal)
            button?.isEnabled = true
            button?.isSelected = false
            button?.layer.borderWidth = 0
            button?.layer.borderColor = nil
        }
        
        nextButton.backgroundColor = UIColor(red: 104/255, green: 195/255, blue: 225/255, alpha: 1.0)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.isHidden = true
        nextButton.isEnabled = true
        nextButton.isSelected = false
    }

    func loadQuestion() {
        // Önce tüm butonları sıfırla
        let buttons = [optionButton1, optionButton2, optionButton3, optionButton4]
        for button in buttons {
            button?.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            button?.setTitleColor(.white, for: .normal)
            button?.isEnabled = true
            button?.isSelected = false
            button?.layer.borderWidth = 0
            button?.layer.borderColor = nil
        }
        
        // Next butonunu sıfırla
        nextButton.backgroundColor = UIColor(red: 104/255, green: 195/255, blue: 225/255, alpha: 1.0)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.isHidden = true
        nextButton.isEnabled = true
        nextButton.isSelected = false
        
        guard currentQuestionIndex < questions.count else {
            disableButtons()
            updateUserStatsInFirestore()
            showFinishAlert()
            return
        }

        // Timer'ı tamamen sıfırla
        timer?.invalidate()
        timer = nil
        timeLeft = 10
        timerLabel.text = "\(timeLeft)"
        timerCircleLayer?.removeAllAnimations()
        setupTimerCircle() // Timer circle'ı yeniden oluştur

        let current = questions[currentQuestionIndex]

        guard current.options.count == 4 else {
            print("Hatalı soru verisi: 4 seçenek yok.")
            currentQuestionIndex += 1
            loadQuestion()
            return
        }

        // Soruyu ve şıkları yükle
        questionLabel.text = current.question
        optionButton1.setTitle(current.options[0], for: .normal)
        optionButton2.setTitle(current.options[1], for: .normal)
        optionButton3.setTitle(current.options[2], for: .normal)
        optionButton4.setTitle(current.options[3], for: .normal)

        let progress = Float(currentQuestionIndex + 1) / Float(questions.count)
        progressBar.setProgress(progress, animated: true)
        questionCountLabel.text = "\(currentQuestionIndex + 1)/\(questions.count)"

        enableButtons()
        startTimer()
    }

    func showNoQuestionsAlert() {
        let alert = UIAlertController(
            title: "Soru Bulunamadı",
            message: "Bu kategoride soru bulunmamaktadır. Lütfen başka bir kategori seçin veya admin ile iletişime geçin.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }

    func disableButtons() {
        [optionButton1, optionButton2, optionButton3, optionButton4].forEach { $0?.isEnabled = false }
    }

    func enableButtons() {
        [optionButton1, optionButton2, optionButton3, optionButton4].forEach { $0?.isEnabled = true }
    }

    func startTimer() {
        // Önceki timer'ı temizle
        timer?.invalidate()
        timer = nil
        
        timeLeft = 10
        timerLabel.text = "\(timeLeft)"
        
        // Timer circle'ı sıfırla ve yeniden başlat
        timerCircleLayer?.removeAllAnimations()
        timerCircleLayer?.strokeEnd = 1.0
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = CFTimeInterval(timeLeft)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        timerCircleLayer?.add(animation, forKey: "timerAnimation")
        
        // Yeni timer'ı başlat
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }

    @objc func updateTimer() {
        timeLeft -= 1
        timerLabel.text = "\(timeLeft)"
        if timeLeft == 0 {
            timer?.invalidate()
            timerCircleLayer?.removeAllAnimations()
            wrongCount += 1
            disableButtons()
            showTimeoutAlert()
        }
    }

    @IBAction func optionSelected(_ sender: UIButton) {
        guard currentQuestionIndex < questions.count else { return }

        timer?.invalidate()
        timerCircleLayer?.removeAllAnimations()

        let selectedAnswer = sender.title(for: .normal)
        let correctAnswer = questions[currentQuestionIndex].correctAnswer

        // Önce tüm butonları normal duruma getir
        let buttons = [optionButton1, optionButton2, optionButton3, optionButton4]
        for button in buttons {
            button?.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
            button?.isSelected = false
        }

        if selectedAnswer == correctAnswer {
            sender.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1) // yeşil
            correctCount += 1
        } else {
            sender.backgroundColor = UIColor(red: 244/255, green: 67/255, blue: 54/255, alpha: 1) // kırmızı
            // doğru olanı işaretle
            for button in buttons {
                if button?.title(for: .normal) == correctAnswer {
                    button?.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1)
                }
            }
            wrongCount += 1
        }

        disableButtons()
        nextButton.isHidden = false
    }

    @IBAction func nextButtonTapped(_ sender: UIButton) {
        resetAllButtons()
        currentQuestionIndex += 1
        
        if currentQuestionIndex >= questions.count {
            disableButtons()
            updateUserStatsInFirestore()
            showFinishAlert()
        } else {
            loadQuestion()
        }
    }

    func showIncorrectAlert() {
        guard !isAlertPresenting else { return }
        isAlertPresenting = true
        
        let alert = UIAlertController(title: "Yanlış!", message: "Tekrar deneyin.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sonraki Soru", style: .default, handler: { _ in
            self.currentQuestionIndex += 1
            self.loadQuestion()
            self.isAlertPresenting = false
        }))
        present(alert, animated: true)
    }

    func showFinishAlert() {
        guard !isAlertPresenting else { return }
        isAlertPresenting = true
        
        let alert = UIAlertController(title: "Quiz Bitti", message: "Doğru: \(correctCount), Yanlış: \(wrongCount)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: {_ in
            self.navigationController?.popViewController(animated: true)
            self.isAlertPresenting = false
        }))
        present(alert, animated: true)
    }
    func showTimeoutAlert() {
        guard !isAlertPresenting else { return }
        isAlertPresenting = true

        let alert = UIAlertController(title: "Süreniz Bitti!", message: "Bu soruya cevap veremediniz.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sonraki Soru", style: .default, handler: { _ in
            self.currentQuestionIndex += 1
            self.loadQuestion()
            self.isAlertPresenting = false
        }))
        present(alert, animated: true)
    }

    func updateUserStatsInFirestore() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                let prevCorrect = snapshot.data()?["correctAnswers"] as? Int ?? 0
                let prevWrong = snapshot.data()?["wrongAnswers"] as? Int ?? 0
                userRef.updateData([
                    "correctAnswers": prevCorrect + self.correctCount,
                    "wrongAnswers": prevWrong + self.wrongCount
                ]) { error in
                    if let error = error {
                        print("Firestore güncelleme hatası: \(error)")
                    }
                }
            } else {
                print("Kullanıcı verisi bulunamadı.")
            }
        }
    }
}
