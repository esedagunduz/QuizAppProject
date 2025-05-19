//
//  UpdateQuestionViewController.swift
//  QuizApp
//
//  Created by ebrar seda gündüz on 19.05.2025.
//

import UIKit
import FirebaseFirestore

class UpdateQuestionViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var tableView: UITableView!

    let db = Firestore.firestore()

    var categories: [String] = []
    var selectedCategory: String?
    var questions: [QueryDocumentSnapshot] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        categoryPicker.delegate = self
        categoryPicker.dataSource = self
        tableView.delegate = self
        tableView.dataSource = self

        fetchCategoriesFromQuestions()
    }

    // MARK: - Firestore: Kategorileri getir
    func fetchCategoriesFromQuestions() {
        db.collection("questions").getDocuments { snapshot, error in
            if let error = error {
                print("Kategori çekme hatası: \(error.localizedDescription)")
                return
            }

            // Tüm dokümanlardaki kategori alanlarını çekip filtrele
            let allCategories = snapshot?.documents.compactMap { doc in
                return doc.data()["category"] as? String
            } ?? []

            // Boş veya aynı olanları ayıklayıp unique dizi yap
            self.categories = Array(Set(allCategories)).filter { !$0.isEmpty }

            print("📁 Bulunan kategoriler: \(self.categories)")

            DispatchQueue.main.async {
                self.categoryPicker.reloadAllComponents()

                if let first = self.categories.first {
                    self.selectedCategory = first
                    self.fetchQuestions(for: first)
                }
            }
        }
    }



    // MARK: - Firestore: Kategoriye göre soruları getir
    func fetchQuestions(for category: String) {
        db.collection("questions").whereField("category", isEqualTo: category).getDocuments { snapshot, error in
            if let error = error {
                print("Soru çekme hatası: \(error)")
                return
            }
            self.questions = snapshot?.documents ?? []
            self.tableView.reloadData()
        }
    }

    // MARK: - UIPickerView Delegate & DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard categories.indices.contains(row) else {
            print("Uyarı: Seçilen satır geçersiz")
            return
        }

        selectedCategory = categories[row]
        fetchQuestions(for: selectedCategory!)
    }


    // MARK: - UITableView Delegate & DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let doc = questions[indexPath.row]
        let data = doc.data()
        let questionText = data["question"] as? String ?? ""
        let correct = data["correctOption"] as? String ?? "?"
        let options = data["options"] as? [String] ?? []

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = questionText
        cell.detailTextLabel?.text = "Cevap: \(correct), Şıklar: \(options.joined(separator: ", "))"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let doc = questions[indexPath.row]
        let data = doc.data()
        let questionText = data["question"] as? String ?? ""
        let options = data["options"] as? [String] ?? ["", "", "", ""]
        let correctOption = data["correctOption"] as? String ?? ""

        let alert = UIAlertController(title: "Soru Güncelle", message: nil, preferredStyle: .alert)

        alert.addTextField { $0.text = questionText }
        alert.addTextField { $0.text = options.indices.contains(0) ? options[0] : "" }
        alert.addTextField { $0.text = options.indices.contains(1) ? options[1] : "" }
        alert.addTextField { $0.text = options.indices.contains(2) ? options[2] : "" }
        alert.addTextField { $0.text = options.indices.contains(3) ? options[3] : "" }
        alert.addTextField { $0.text = correctOption }

        alert.addAction(UIAlertAction(title: "Güncelle", style: .default, handler: { _ in
            let updatedQuestion = alert.textFields?[0].text ?? ""
            let updatedOptions = [
                alert.textFields?[1].text ?? "",
                alert.textFields?[2].text ?? "",
                alert.textFields?[3].text ?? "",
                alert.textFields?[4].text ?? ""
            ]
            let updatedCorrect = alert.textFields?[5].text ?? ""

            let updatedData: [String: Any] = [
                "question": updatedQuestion,
                "options": updatedOptions,
                "correctOption": updatedCorrect,
                "category": self.selectedCategory ?? ""
            ]

            self.db.collection("questions").document(doc.documentID).updateData(updatedData) { err in
                if let err = err {
                    print("Güncelleme hatası: \(err)")
                } else {
                    print("Soru güncellendi.")
                    self.fetchQuestions(for: self.selectedCategory!)
                }
            }
        }))

        alert.addAction(UIAlertAction(title: "Sil", style: .destructive, handler: { _ in
            self.db.collection("questions").document(doc.documentID).delete { err in
                if let err = err {
                    print("Silme hatası: \(err)")
                } else {
                    print("Soru silindi.")
                    self.fetchQuestions(for: self.selectedCategory!)
                }
            }
        }))

        alert.addAction(UIAlertAction(title: "İptal", style: .cancel, handler: nil))

        present(alert, animated: true)
    }
}
