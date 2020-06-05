//
//  RegisterViewController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-26.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class RegisterViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var rePasswordTextField: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.configureView()
        self.closeErrorMessage()
    }
    
    private func configureView() {
        self.registerButton.layer.cornerRadius = Constants.Numbers.cornerRadius
        self.emailTextField.roundedCorner()
        self.nameTextField.roundedCorner()
        self.lastNameTextField.roundedCorner()
        self.passwordTextField.roundedCorner()
        self.rePasswordTextField.roundedCorner()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @IBAction func registerUser(_ sender: Any) {
        self.closeKeyboard()
        let message = validateFields()
        
        if (message != nil) {
            errorMessageLabel.text = message
            errorMessageLabel.alpha = 1
            return
        }
        
        self.showSpinner(onView: self.view)
        createUserLogin()
    }
    
    func createUserLogin() {
        let auth = Auth.auth()
        
        auth.createUser(withEmail: self.emailTextField.text!, password: self.passwordTextField.text!) { (result, error) in
            
            if (error == nil && result != nil) {
                
                self.sendEmailVerification(auth: auth)
            } else {
                self.removeSpinner()
                self.showAlert(title: "Error", message: "Se produjo un error al registrar Usuario, favor volver a intentar")
            }
        }
    }
    
    func sendEmailVerification(auth: Auth) {
        let changeRequest = auth.currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = "\(self.nameTextField.text!) \(self.lastNameTextField.text!)"
        changeRequest?.commitChanges(completion: { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
        
        
        let uid = auth.currentUser?.uid
        auth.currentUser?.sendEmailVerification(completion: { (error) in
            if (error == nil) {
                self.saveUser(uid: uid!)
            } else {
                self.removeSpinner()
            }
        })
    }
    
    func saveUser(uid: String) {
        let database = Database.database().reference()
        
        let dataClient: [String: Any] = [
            "email": self.emailTextField.text!,
            "lastName": self.lastNameTextField.text!,
            "name": self.nameTextField.text!,
            "uid": uid
        ]
        
        database
        .child("users")
        .child(uid)
            .setValue(dataClient) { (error:Error?, reference: DatabaseReference) in
                self.removeSpinner()
                
                if let error = error {
                    self.showAlert(title: "Error", message: "Se produjo un error inesperado, favor volver a probar")
                    print(error)
                } else {
                    self.signOutUser()
                    self.cleanView()
                    self.goBackController()
                }
        }
    }
    
    func signOutUser() {
        do {
            try Auth.auth().signOut()
        } catch let err {
            print(err)
        }
    }
    
    func cleanView() {
        self.emailTextField.text = ""
        self.nameTextField.text = ""
        self.lastNameTextField.text = ""
        self.passwordTextField.text = ""
        self.rePasswordTextField.text = ""
    }
    
    func goBackController() {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        }
    }
    
    func validateFields() -> String? {
        if (self.emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            self.nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            self.lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            self.passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            self.rePasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
            
            return "Todos los campos son obligatorios"
        }
        let email = self.emailTextField.text!
        if (!email.isValidEmail()) {
            return "Debe ingresar un Email valido"
        }
        
        if (self.passwordTextField.text != self.rePasswordTextField.text) {
            return "Las contraseñas no coinciden"
        }
        
        return nil
    }
    
    func closeErrorMessage() {
        self.errorMessageLabel.text = ""
        self.errorMessageLabel.alpha = 0
    }
    
    func showErrorMessage(message: String) {
        self.errorMessageLabel.text = message
        self.errorMessageLabel.alpha = 1
    }
    
    func closeKeyboard() {
        self.emailTextField.resignFirstResponder()
        self.nameTextField.resignFirstResponder()
        self.lastNameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        self.rePasswordTextField.resignFirstResponder()
    }
    
    func showAlert(title: String, message: String) {
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: nil))
        
        self.present(alertView, animated: true, completion: nil)
    }
}
