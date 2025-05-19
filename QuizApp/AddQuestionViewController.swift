//
//  AddQuestionViewController.swift
//  QuizApp
//
//  Created by ebrar seda gündüz on 5.05.2025.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class AddQuestionViewController: UIViewController {
    
    // Ana scroll view - klavye açıldığında içeriği kaydırmak için
    @IBOutlet weak var scrollView: UIScrollView!
    
    // Ana konteyner view - beyaz arka planlı, yuvarlak köşeli
    @IBOutlet weak var containerView: UIView!
    
    // Üst başlık etiketi
    @IBOutlet weak var titleLabel: UILabel!
    
    // Kategori bölümü
    @IBOutlet weak var categoryTitleLabel: UILabel!
    @IBOutlet weak var categoryDescriptionLabel: UILabel!
    @IBOutlet weak var categoryTextField: UITextField!
    
    // Soru bölümü
    @IBOutlet weak var questionTitleLabel: UILabel!
    @IBOutlet weak var questionDescriptionLabel: UILabel!
    @IBOutlet weak var questionTextField: UITextField!
    
    // Cevaplar bölümü
    @IBOutlet weak var answersTitleLabel: UILabel!
    @IBOutlet weak var answersDescriptionLabel: UILabel!
    
    // Cevap metin alanları
    @IBOutlet weak var option1TextField: UITextField!
    @IBOutlet weak var option2TextField: UITextField!
    @IBOutlet weak var option3TextField: UITextField!
    @IBOutlet weak var option4TextField: UITextField!
    
    
  
    
    // Ekle butonu
    @IBOutlet weak var addButton: UIButton!
    
    // Kategori seçimleri için picker view
    let categoryPicker = UIPickerView()
    let categories = ["Sports", "History", "Science", "Technology", "Geography"]
    var correctAnswerIndex: Int?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupCategoryPicker()
        checkAdminStatus()
        setupKeyboardHandling()
    }
    
    func setupUI() {
        // Ana başlık ayarları
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .white
        
        // Konteyner view ayarları
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        containerView.backgroundColor = .white
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.masksToBounds = false
        
        // Başlık etiketleri
        configureLabel(categoryTitleLabel, title: "Quiz Category", size: 22, weight: .semibold)
        configureLabel(questionTitleLabel, title: "Quiz Question", size: 22, weight: .semibold)
        configureLabel(answersTitleLabel, title: "Quiz Answers", size: 22, weight: .semibold)
        
        // Açıklama etiketleri
        configureLabel(categoryDescriptionLabel, title: "Hangi kategoriyi seçmek istersiniz?", size: 16, weight: .regular, color: .lightGray)
        configureLabel(questionDescriptionLabel, title: "Sormak istediğiniz soruyu yazınız.", size: 16, weight: .regular, color: .lightGray)
        configureLabel(answersDescriptionLabel, title: "Doğru cevabı işaretleyiniz.", size: 16, weight: .regular, color: .lightGray)
        
        // Metin alanlarını ayarla
        configureTextField(categoryTextField, placeholder: "Select a category")
        configureTextField(questionTextField, placeholder: "Enter the quiz question")
        configureTextField(option1TextField, placeholder: "Quiz Answer #1")
        configureTextField(option2TextField, placeholder: "Quiz Answer #2")
        configureTextField(option3TextField, placeholder: "Quiz Answer #3")
        configureTextField(option4TextField, placeholder: "Quiz Answer #4")
      
        
      
    }
    
    func configureLabel(_ label: UILabel, title: String, size: CGFloat, weight: UIFont.Weight, color: UIColor = .black) {
        label.text = title
        label.font = UIFont.systemFont(ofSize: size, weight: weight)
        label.textColor = color
    }
    
    func configureTextField(_ textField: UITextField, placeholder: String) {
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0) // Açık gri arka plan
        textField.layer.cornerRadius = 15
        textField.layer.masksToBounds = true
        
        // İç boşluk ekle
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        // Hafif gölge ekle
        textField.layer.shadowColor = UIColor.lightGray.cgColor
        textField.layer.shadowOffset = CGSize(width: 0, height: 1)
        textField.layer.shadowRadius = 2
        textField.layer.shadowOpacity = 0.2
    }
    
    func setupKeyboardHandling() {
        // Klavye açıldığında ve kapandığında bildirimleri al
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Ekrana dokununca klavyeyi kapat
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupCategoryPicker() {
        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        
        // Picker'ı doğrudan inputView olarak ayarla
        categoryTextField.inputView = categoryPicker
        
        // Üstüne bir toolbar ekle
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePicker))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.setItems([space, doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        categoryTextField.inputAccessoryView = toolbar
    }



    
    @objc func donePicker() {
        let selectedRow = categoryPicker.selectedRow(inComponent: 0)
        if selectedRow >= 0 && selectedRow < categories.count {
            categoryTextField.text = categories[selectedRow]
        }
        view.endEditing(true)
    }
    
    func checkAdminStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let isAdmin = document.data()?["isAdmin"] as? Bool ?? false
                
                if !isAdmin {
                    self.showNotAuthorizedAlert()
                }
            }
        }
    }

    func showNotAuthorizedAlert() {
        let alert = UIAlertController(title: "Yetkisiz Erişim", message: "Bu işlemi sadece adminler yapabilir.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func selectCorrectAnswer(_ sender: UIButton) {
        correctAnswerIndex = sender.tag

        // Tüm butonları varsayılan duruma döndür
        for index in 0...3 {
            if let button = view.viewWithTag(index) as? UIButton {
                button.setImage(UIImage(systemName: "circle"), for: .normal)
                button.tintColor = .lightGray // varsayılan renk
            }
        }

        // Seçilen butonu işaretle
        sender.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
        sender.tintColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0) // yeşil renk
    }



    @IBAction func addQuestionTapped(_ sender: UIButton) {
        guard let category = categoryTextField.text,
              let question = questionTextField.text,
              let opt1 = option1TextField.text,
              let opt2 = option2TextField.text,
              let opt3 = option3TextField.text,
              let opt4 = option4TextField.text,
              !category.isEmpty, !question.isEmpty,
              !opt1.isEmpty, !opt2.isEmpty, !opt3.isEmpty, !opt4.isEmpty else {
            showAlert(title: "Hata", message: "Tüm alanlar doldurulmalı.")
            return
        }

        guard let correctIndex = correctAnswerIndex else {
            showAlert(title: "Hata", message: "Doğru cevabı seçmelisiniz.")
            return
        }

        let options = [opt1, opt2, opt3, opt4]
        let correctOption = options[correctIndex]

        let db = Firestore.firestore()
        let questionData: [String: Any] = [
            "category": category,
            "question": question,
            "options": options,
            "correctOption": correctOption
        ]

        db.collection("questions").addDocument(data: questionData) { error in
            if let error = error {
                self.showAlert(title: "Hata", message: "Soru eklenemedi: \(error.localizedDescription)")
            } else {
                self.showAlert(title: "Başarılı", message: "Soru başarıyla eklendi.") {
                    self.clearFields()
                }
            }
        }
    }
    
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    func clearFields() {
        questionTextField.text = ""
        option1TextField.text = ""
        option2TextField.text = ""
        option3TextField.text = ""
        option4TextField.text = ""
       
        // Kategori alanını temizleme çünkü genellikle aynı kategoride birden fazla soru eklenebilir
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension AddQuestionViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryTextField.text = categories[row]
    }
}
