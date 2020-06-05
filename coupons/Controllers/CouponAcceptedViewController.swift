//
//  CouponAcceptedViewController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-23.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CouponAcceptedViewController: UIViewController {

    @IBOutlet weak var couponImageView: UIImageView!
    @IBOutlet weak var couponTitleLabel: UILabel!
    @IBOutlet weak var couponExpirationLabel: UILabel!
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    
    var keyClientCoupon: String = ""
    var clientCoupon = ClientCoupon()
    var addNavigationItem = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.cancelButton.roundedCorner()
        self.couponImageView.roundedCorner()
        
        self.loadDataCoupon(showSpinner: false)
    }
    
    private func loadDataCoupon(showSpinner: Bool) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        if (showSpinner) {
            self.showSpinner(onView: self.view)
        }
        
        let database = Database.database().reference()
        
        database.child("clientCoupon")
            .child(uid)
            .child(self.keyClientCoupon)
            .observeSingleEvent(of: .value) { (snapshot) in
            
                let value = snapshot.value as? NSDictionary
                self.dictionaryToClientCoupon(value: value, key: snapshot.key)
                
                self.fillClientCouponData(uid: uid)
        }
    }
    
    func dictionaryToClientCoupon(value: NSDictionary?, key: String) {
        self.clientCoupon.couponAvailable = value?["couponAvailable"] as? Int
        self.clientCoupon.dateStatus = value?["dateStatus"] as? String
        self.clientCoupon.expiration = value?["expiration"] as? String
        self.clientCoupon.keyClientCoupon = key
        self.clientCoupon.nameCoupon = value?["nameCoupon"] as? String
        self.clientCoupon.status = value?["status"] as? Int
        self.clientCoupon.text = value?["text"] as? String
        self.clientCoupon.totalCoupon = value?["totalCoupon"] as? Int
        self.clientCoupon.uidEmployee = value?["uidEmployee"] as? String
        self.clientCoupon.urlImage = value?["urlImage"] as? String
    }
    
    func fillClientCouponData(uid: String) {
        self.couponTitleLabel.text = self.clientCoupon.nameCoupon
        self.couponExpirationLabel.text = self.clientCoupon.expiration
        self.detailTextView.text = self.clientCoupon.text
        self.couponImageView.load(urlString: self.clientCoupon.urlImage)
        let qrCodeImage = self.generateQrCode(from: "\(uid)__\(self.keyClientCoupon)")
        self.qrCodeImageView.image = qrCodeImage
        self.statusLabel.textColor = .black
        let today = Date()
        
        if (self.clientCoupon.status == CouponStatus.deleted.rawValue) {
            self.statusLabel.textColor = .red
            self.statusLabel.text = "Cupón Cancelado en \(self.clientCoupon.dateStatus!)"
        } else if (self.clientCoupon.status == CouponStatus.approved.rawValue) {
            self.statusLabel.text = "Cupón Útilizado en \(self.clientCoupon.dateStatus!)"
        } else {
            if (self.clientCoupon.expiration.stringToDate()! < today.toNow()!) {
                self.statusLabel.textColor = .red
                self.statusLabel.text = "Cupón Vencido"
            } else {
                self.statusLabel.text = "Cupón Vigente"
            }
        }
        
        self.removeSpinner()
    }
    
    func transitionToHome() {
        let homeController = storyboard?.instantiateViewController(identifier: Constants.StoryBoardNames.homeViewController) as? CouponTabBarController
        view.window?.rootViewController = homeController
        view.window?.makeKeyAndVisible()
    }
    
    func generateQrCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }

    @IBAction func cancelCoupon(_ sender: Any) {
        let confirmMessage = UIAlertController(title: "Confirmación", message: "¿Está seguro que desea cancelar el cupón?", preferredStyle: .alert)
        confirmMessage.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        confirmMessage.addAction(UIAlertAction(title: "Si, Seguro", style: .default, handler: { (alertAction) in
            self.showSpinner(onView: self.view)
            self.validationCoupon()
        }))
        
        self.present(confirmMessage, animated: true, completion: nil)
    }
    
    func validationCoupon() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let database = Database.database().reference()
        
        database.child("clientCoupon")
            .child(uid)
            .child(self.keyClientCoupon)
            .observeSingleEvent(of: .value) { (snapshot) in
                
                let value = snapshot.value as? NSDictionary
                self.dictionaryToClientCoupon(value: value, key: snapshot.key)
                
                if (self.clientCoupon.status == CouponStatus.approved.rawValue) {
                    self.removeSpinner()
                    self.showMessage(title: "Advertencia", message: "No es posible cancelar el cupón debido a que ya fue utilizado")
                    return
                }
                
                if (self.clientCoupon.status == CouponStatus.deleted.rawValue) {
                    self.removeSpinner()
                    self.showMessage(title: "Advertencia", message: "No es posible cancelar un cupón que ya fue eliminado")
                    return
                }
                
                self.updateClientCoupon(uid: uid)
        }
    }
    
    func updateClientCoupon(uid: String) {
        let today = Date()
        
        let dataClientCoupon: [String: Any] = [
            "couponAvailable": self.clientCoupon.couponAvailable!,
            "dateStatus": today.dateToString()!,
            "expiration": self.clientCoupon.expiration!,
            "nameCoupon": self.clientCoupon.nameCoupon!,
            "status": CouponStatus.deleted.rawValue,
            "text": self.clientCoupon.text!,
            "totalCoupon": self.clientCoupon.totalCoupon!,
            "uidEmployee": self.clientCoupon.uidEmployee!,
            "urlImage": self.clientCoupon.urlImage!
        ]
        
        let database = Database.database().reference()
        
        database.child("clientCoupon")
            .child(uid)
            .child(self.keyClientCoupon)
            .setValue(dataClientCoupon) { (error, databaseReference) in
                
                if let error = error {
                    self.removeSpinner()
                    self.showMessage(title: "Error", message: "Se produjo un error al eliminar el Cupón, favor volver a intentar \(error.localizedDescription)")
                    print("error \(error)")
                } else {
                    self.updateCoupon()
                }
                
        }
    }
    
    func updateCoupon() {
        let database = Database.database().reference()
        
        database.child("coupons")
            .child(self.keyClientCoupon)
            .observeSingleEvent(of: .value) { (snapshot) in
                
                let value = snapshot.value as? NSDictionary
                let couponAvailable = value?["couponAvailable"] as? Int
                let expiration = value?["expiration"] as? String
                let nameCoupon = value?["nameCoupon"] as? String
                let text = value?["text"] as? String
                let totalCoupon = value?["totalCoupon"] as? Int
                let urlImage = value?["urlImage"] as? String
                
                let dataCoupon: [String: Any] = [
                    "couponAvailable": couponAvailable! + 1,
                    "expiration": expiration!,
                    "nameCoupon": nameCoupon!,
                    "text": text!,
                    "totalCoupon": totalCoupon!,
                    "urlImage": urlImage!]
                
                database.child("coupons")
                    .child(self.keyClientCoupon)
                    .setValue(dataCoupon)
                
                self.loadDataCoupon(showSpinner: false)
        }
    }
    
    func showMessage(title: String, message: String) {
        let message = UIAlertController(title: title, message: message, preferredStyle: .alert)
        message.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: nil))
        
        self.present(message, animated: true, completion: nil)
    }
}
