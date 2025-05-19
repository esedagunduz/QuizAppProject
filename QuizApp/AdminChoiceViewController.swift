//
//  AdminChoiceViewController.swift
//  QuizApp
//
//  Created by ebrar seda gündüz on 19.05.2025.
//



import UIKit

class AdminChoiceViewController: UIViewController {

    @IBAction func addQuestionTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToAddQuestion", sender: self)
    }

    @IBAction func updateQuestionTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToUpdateQuestion", sender: self)
    }
}
