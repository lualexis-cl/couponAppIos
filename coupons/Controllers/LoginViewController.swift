//
//  LoginViewController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-18.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var forgotPasswordLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.configureView()
        
        self.forgotPasswordLabel.isUserInteractionEnabled = true
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.labelClicked(_:)))
        self.forgotPasswordLabel.addGestureRecognizer(gestureRecognizer)
        
        dismissErrorMessage()
    }
    
    private func configureView() {
        self.loginButton.layer.cornerRadius = Constants.Numbers.cornerRadius
        self.registerButton.layer.cornerRadius = Constants.Numbers.cornerRadius
        self.emailTextField.roundedCorner()
        self.passwordTextField.roundedCorner()
    }
    
    @objc func labelClicked(_ sender: Any) {
        self.performSegue(withIdentifier: "segueForgotPassword", sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dismissErrorMessage()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func validateFields() -> String? {
        if (emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
            return "Debe ingresar Email y Contraseña"
        }
        
        return nil
    }

    func dismissErrorMessage() {
        errorLabel.alpha = 0
        errorLabel.text = ""
    }
    
    func showError(errorMessage: String) {
        errorLabel.alpha = 1
        errorLabel.text = errorMessage
    }
    
    @IBAction func logIn(_ sender: Any) {
        self.closeKeyboard()
        let error = validateFields()
        
        if (error != nil) {
            showError(errorMessage: error!)
            return
        }
        self.showSpinner(onView: self.view)
        let email = self.emailTextField.text!
        let password = self.passwordTextField.text!
        
        Auth.auth().signIn(withEmail: email, password: password) { (userResult, error) in
            if (error == nil && userResult != nil) {
                guard let isEmailVerified = userResult?.user.isEmailVerified else { return }
                self.removeSpinner()
                
                if (isEmailVerified) {
                    print("Uid Login: " + (userResult?.user.uid ??  ""))
                    self.transitionToHome()
                } else {
                    self.logout()
                    self.showMessage(title: "Advertencia", message: "Debe verificar su dirección de email para acceder a los beneficios")
                }
            } else {
                self.removeSpinner()
                self.showError(errorMessage: "Usuario y/o Contraseña incorrectos")
            }
        }
    }
    
    func closeKeyboard() {
        self.emailTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
    }
    
    func transitionToHome() {
        let homeController = storyboard?.instantiateViewController(identifier: Constants.StoryBoardNames.homeViewController) as? CouponTabBarController
        view.window?.rootViewController = homeController
        view.window?.makeKeyAndVisible()
    }
    
    func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch let error {
            print(error)
        }
    }

}
