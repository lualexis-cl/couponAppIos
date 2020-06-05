//
//  MyPerfilViewController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-21.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class MyPerfilViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var reNewPasswordTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    var user = User()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.nameTextField.delegate = self
        self.configureView()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        self.loadDataUser()
    }
    
    private func configureView() {
        self.saveButton.layer.cornerRadius = Constants.Numbers.cornerRadius
        self.logoutButton.layer.cornerRadius = Constants.Numbers.cornerRadius
        self.emailTextField.roundedCorner()
        self.nameTextField.roundedCorner()
        self.lastNameTextField.roundedCorner()
        self.passwordTextField.roundedCorner()
        self.newPasswordTextField.roundedCorner()
        self.reNewPasswordTextField.roundedCorner()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func transitionToHome() {
        let homeController = storyboard?.instantiateViewController(identifier: Constants.StoryBoardNames.homeViewController) as? CouponTabBarController
        view.window?.rootViewController = homeController
        view.window?.makeKeyAndVisible()
    }
    
    func loadDataUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        self.showSpinner(onView: self.view)
        let database = Database.database().reference()
        
        database
            .child("users")
            .child(uid)
            .observeSingleEvent(of: .value) { (snapshot) in
                
                let value = snapshot.value as? NSDictionary
                self.user.name = value?["name"] as? String
                self.user.email = value?["email"] as? String
                self.user.lastName = value?["lastName"] as? String
                self.user.uid = value?["uid"] as? String
                
                self.fillDataClient()
        }
    }
    
    func fillDataClient() {
        self.emailTextField.text = self.user.email
        self.nameTextField.text = self.user.name
        self.lastNameTextField.text = self.user.lastName
        
        self.removeSpinner()
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        print("keyboard")
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            self.scrollView.contentInset = .zero
        } else {
            self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset
    }
    
    func validateFields() -> String? {
        
        if (self.nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
            self.lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
            return "Nombre y Apellido no pueden estar vacios"
        }
        
        if (self.passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "") {
            if (self.newPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" ||
                self.reNewPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ==  "") {
                return "Debe ingresar el nuevo password y su confirmación si desea cambiarlo"
            }
        }
        
        if (self.newPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "") {
            if (self.passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                return "Debe ingresar la contraseña actual"
            }
        }
        
        if (self.reNewPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "" && self.newPasswordTextField.text != self.reNewPasswordTextField.text) {
            return "La nueva contraseña no coincidice con su confirmación"
        }
        
        return nil
    }
    
    @IBAction func saveUpdate(_ sender: Any) {
        self.nameTextField.resignFirstResponder()
        self.lastNameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        self.newPasswordTextField.resignFirstResponder()
        self.reNewPasswordTextField.resignFirstResponder()
        let error = self.validateFields()
        
        if (error != nil) {
            showAlert(title: "Error", message: error!)
            return
        }
        
        self.showSpinner(onView: self.view
        )
        let dataClient: [String: Any] = [
            "email": self.user.email!,
            "lastName": self.lastNameTextField.text!,
            "name": self.nameTextField.text!,
            "uid": self.user.uid!
        ]
        
        let database = Database.database().reference()
        
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = "\(self.nameTextField.text!) \(self.lastNameTextField.text!)"
        changeRequest?.commitChanges(completion: { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
        
        database
            .child("users")
            .child(self.user.uid!)
        //.childByAutoId()
            .setValue(dataClient) {
                (error:Error?, ref:DatabaseReference) in
                
                if let error = error {
                    self.removeSpinner()
                    self.showAlert(title: "Error", message: "Se produjo un error inesperado, volver a probar nuevamente")
                    print("error \(error)")
                } else {
                    if (self.passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) != "") {
                        self.updatePassword()
                    } else {
                        self.removeSpinner()
                        self.showAlert(title: "Confirmación", message: "Información actualizada correctamente")
                    }
                }
        }
    }
    
    func updatePassword() {
        Auth.auth().signIn(withEmail: self.user.email, password: passwordTextField.text!) { (dataResult, error) in
            if (error == nil && dataResult != nil) {
                dataResult?.user.updatePassword(to: self.newPasswordTextField.text!, completion: { (error) in
                    if (error == nil) {
                        self.removeSpinner()
                        self.showAlert(title: "Confirmación", message: "Información actualizada correctamente")
                        
                        self.passwordTextField.text = ""
                        self.newPasswordTextField.text = ""
                        self.reNewPasswordTextField.text = ""
                    } else {
                        self.removeSpinner()
                        self.showAlert(title: "Error", message: "No fue posible actualizar el password")
                    }
                })
            } else {
                self.removeSpinner()
                self.showAlert(title: "Error", message: "Error password actual no corresponde")
            }
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        do {
            try Auth.auth().signOut()
        } catch _ {
            print("Error")
        }
        
        transitionToHome()
    }
    
    func showAlert(title: String, message: String) {
        let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: nil))
        
        self.present(alertView, animated: true, completion: nil)
    }
}
