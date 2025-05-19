//
//  RegisterViewController.swift
//  QuizApp
//
//  Created by ebrar seda gündüz on 3.05.2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class RegisterViewController: UIViewController {

    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    let db = Firestore.firestore()

    @IBAction func registerTapped(_ sender: UIButton) {
        guard let nickname = nicknameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text else { return }
        
        // Email format kontrolü
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            let alert = UIAlertController(title: "Hata", message: "Lütfen geçerli bir email adresi giriniz.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Şifre kriterleri kontrolü
        let passwordRegex = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        if !passwordPredicate.evaluate(with: password) {
            let alert = UIAlertController(title: "Hata", message: "Şifre en az 8 karakter uzunluğunda olmalı ve en az bir harf ve bir rakam içermelidir.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Email ve nickname kontrolü
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Email check error: \(error)")
                return
            }
            
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                let alert = UIAlertController(title: "Hata", message: "Bu email adresi zaten kullanımda.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                self?.present(alert, animated: true)
                return
            }
            
            // Nickname kontrolü
            self?.db.collection("users").whereField("nickname", isEqualTo: nickname).getDocuments { [weak self] (snapshot, error) in
                if let error = error {
                    print("Nickname check error: \(error)")
                    return
                }
                
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    let alert = UIAlertController(title: "Hata", message: "Bu kullanıcı adı zaten kullanımda.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                    self?.present(alert, animated: true)
                    return
                }
                
                // Tüm kontroller başarılı, kullanıcı kaydını başlat
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        print("Register Error: \(error.localizedDescription)")
                        let alert = UIAlertController(title: "Hata", message: "Kayıt işlemi sırasında bir hata oluştu: \(error.localizedDescription)", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                        self?.present(alert, animated: true)
                        return
                    }

                    guard let uid = authResult?.user.uid else { return }

                    // Firebase Firestore'a kullanıcı verilerini kaydet
                    self?.db.collection("users").document(uid).setData([
                        "nickname": nickname,
                        "email": email,
                        "correctAnswers": 0,
                        "wrongAnswers": 0,
                        "isAdmin": false
                    ]) { err in
                        if let err = err {
                            print("Firestore save error: \(err)")
                            let alert = UIAlertController(title: "Hata", message: "Kullanıcı bilgileri kaydedilirken bir hata oluştu.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Tamam", style: .default))
                            self?.present(alert, animated: true)
                        } else {
                            // Firestore'a kaydettikten sonra, kullanıcıyı Login ekranına yönlendir
                            self?.performSegue(withIdentifier: "goToLogin", sender: self)
                        }
                    }
                }
            }
        }
    }
}
