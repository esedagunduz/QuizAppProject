//
//  LoginViewController.swift
//  QuizApp
//
//  Created by ebrar seda gündüz on 3.05.2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    let db = Firestore.firestore()

    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Hata", message: "Gerekli alanları doldurmalısınız")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                if let errorCode = AuthErrorCode(rawValue: error._code) {
                    switch errorCode {
                    case .wrongPassword:
                        self.showAlert(title: "Hata", message: "Şifre hatalı")
                    case .invalidEmail:
                        self.showAlert(title: "Hata", message: "Geçerli bir email adresi girin")
                    case .userNotFound:
                        self.showAlert(title: "Hata", message: "Bu email ile kayıtlı kullanıcı bulunamadı")
                    case .invalidCredential, .expiredActionCode, .invalidActionCode, .userDisabled:
                        self.showAlert(title: "Hata", message: "Giriş yapılamadı. Lütfen email ve şifrenizi kontrol edin.")
                    default:
                        self.showAlert(title: "Hata", message: "Bir hata oluştu: \(error.localizedDescription)")
                    }
                } else {
                    self.showAlert(title: "Hata", message: "Beklenmedik bir hata oluştu.")
                }
                return
            }

            guard let uid = authResult?.user.uid else { return }

            // Kullanıcı Firestore'da zaten var mı kontrol et
            let userRef = self.db.collection("users").document(uid)
            userRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let isAdmin = document.data()?["isAdmin"] as? Bool ?? false
                    
                    if isAdmin {
                        // Adminse, soru ekleme ekranına git
                        self.performSegue(withIdentifier: "goToAdminChoice", sender: self)
                    } else {
                        // Admin değilse, başka bir ekrana yönlendirebilirsiniz
                        self.performSegue(withIdentifier: "goToCategory", sender: self)
                    }
                } else {
                    // Kullanıcı Firestore'da yoksa, verilerini kaydet
                    self.db.collection("users").document(uid).setData([
                        "nickname": "Default Nickname",
                        "email": email,
                        "correctAnswers": 0,
                        "wrongAnswers": 0
                    ]) { err in
                        if let err = err {
                            print("Firestore save error: \(err)")
                        } else {
                            print("Yeni kullanıcı Firestore'a kaydedildi.")
                        }
                    }
                    
                    // Başarılı giriş sonrası Category ekranına geçiş yap
                    self.showAlert(title: "Başarılı", message: "Başarıyla giriş yapıldı") {
                        self.performSegue(withIdentifier: "goToCategory", sender: self)
                    }
                }
            }
        }
    }

    @IBAction func goToRegister(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let registerVC = storyboard.instantiateViewController(withIdentifier: "RegisterVC")
        self.present(registerVC, animated: true, completion: nil)
    }
    
    // Yardımcı fonksiyonlar
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
