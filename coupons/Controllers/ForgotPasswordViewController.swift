//
//  ForgotPasswordViewController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-06-01.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailLabel: UITextField!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.configureView()
        self.clearErrorMessage()
    }
    
    private func configureView() {
        self.forgotPasswordButton.layer.cornerRadius = Constants.Numbers.cornerRadius
        self.emailLabel.roundedCorner()
    }
    
    func clearErrorMessage() {
        self.errorMessageLabel.text = ""
        self.errorMessageLabel.alpha = 0
    }
    
    func showMessageError(message: String) {
        self.errorMessageLabel.text = message
        self.errorMessageLabel.alpha = 1
    }
    
    func validation() -> String? {
        if (self.emailLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
            return "Debe ingresar el Email"
        }
        
        let email = self.emailLabel.text!
        if (!email.isValidEmail()) {
            return "Debe ingresar un Email valido"
        }
        
        return nil
    }
    
    @IBAction func forgotPasswordAction(_ sender: Any) {
        let message = validation()
        
        if (message != nil) {
            self.showMessageError(message: message!)
            return
        }
        
        self.showMessageError(message: "")
        
        Auth.auth().sendPasswordReset(withEmail: self.emailLabel.text!) { (error) in
            if let error = error {
                self.showAlertMessage(title: "Error", message: "Se produjo un error al intentar enviar un correo, verifique si su correo está correctamente ingresado o si existe en nuestros registros")
                print(error.localizedDescription)
            } else {
                self.showAlertMessage(title: "Confirmación", message: "Correo enviado correctamente, verifique su email y recupere su password")
            }
        }
    }
    
    func showAlertMessage(title: String, message: String) {
        let alertMessage = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertMessage.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: nil))
        
        self.present(alertMessage, animated: true, completion: nil)
    }
}
