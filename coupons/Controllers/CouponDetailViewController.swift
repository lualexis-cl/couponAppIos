//
//  CouponDetailViewController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-17.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class CouponDetailViewController: UIViewController {

    @IBOutlet weak var couponTitleLabel: UILabel!
    @IBOutlet weak var expirationLabel: UILabel!
    @IBOutlet weak var numberCouponAvailableLabel: UILabel!
    @IBOutlet weak var couponImage: UIImageView!
    @IBOutlet weak var conditionTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    
    var coupon = Coupon()
    var keyCoupon = ""
    var itHasCoupon = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.saveButton.roundedCorner()
        self.couponImage.roundedCorner()
        
        self.loadDataCoupon()
    }
    
    func loadDataCoupon() {
        let database = Database.database().reference()
        
        database
            .child("coupons")
            .child(keyCoupon)
            .observeSingleEvent(of: .value) { (snapshot) in
                let value = snapshot.value as? NSDictionary
                self.dictionaryToCoupon(value: value, key: snapshot.key)
                
                self.fillCouponData()
        }
    }
    
    func dictionaryToCoupon(value: NSDictionary?, key: String) {
        self.coupon.couponAvailable = value?["couponAvailable"] as? Int
        self.coupon.expiration = value?["expiration"] as? String
        self.coupon.keyCoupon = key
        self.coupon.nameCoupon = value?["nameCoupon"] as? String
        self.coupon.text = value?["text"] as? String
        self.coupon.totalCoupon = value?["totalCoupon"] as? Int
        self.coupon.urlImage = value?["urlImage"] as? String
    }
    
    func fillCouponData() {
        self.couponTitleLabel.text = self.coupon.nameCoupon
        self.expirationLabel.text = self.coupon.expiration
        self.conditionTextView.text = self.coupon.text
        self.numberCouponAvailableLabel.text = "\(self.coupon.couponAvailable!)"
        
        self.couponImage.load(urlString: self.coupon.urlImage)
    }
    
    @IBAction func saveCoupon(_ sender: Any) {
        print("Click saveCoupon")
        let user = Auth.auth().currentUser
        
        if (user == nil) {
            self.showMessage(title: "Advertencia", message: "Debe iniciar sesión para acceder a los beneficios")
            return
        }
        self.getLatestDataCoupon()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("Prepare")
        if (segue.identifier == "segueFromCouponToAccepted") {
            let controller = segue.destination as! CouponAcceptedViewController
            controller.keyClientCoupon = self.keyCoupon
            controller.addNavigationItem = true
        }
    }
    
    func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Aceptar", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func getLatestDataCoupon() {
        self.showSpinner(onView: self.view)
        let database = Database.database().reference()
        
        database
            .child("coupons")
            .child(self.keyCoupon)
            .observeSingleEvent(of: .value) { (snapshot) in
                
                let value = snapshot.value as? NSDictionary
                self.dictionaryToCoupon(value: value, key: snapshot.key)
                
                if (self.coupon.couponAvailable <= 0) {
                    self.removeSpinner()
                    self.showMessage(title: "Advertencia", message: "No quedan cupones disponibles, no es posible obtener el cupón")
                    return
                }
                let today = Date()
                if (self.coupon.expiration.stringToDate()! < today.toNow()!) {
                    self.removeSpinner()
                    self.showMessage(title: "Advertencia", message: "Cupón se encuentra vencido, no es posible obtener el cupón")
                    return
                }
                
                self.doesItHaveCoupon()
        }
        
    }
    
    func doesItHaveCoupon() {
        let currentUser = Auth.auth().currentUser
        
        guard let uid = currentUser?.uid else { return }
        let database = Database.database().reference()
        
        database.child("clientCoupon")
            .child(uid)
            .child(self.keyCoupon)
            .observeSingleEvent(of: .value) { (data) in
                
                if (data.exists()) {
                    let value = data.value as? NSDictionary
                    let status = value?["status"] as! Int
                    
                    if (status != CouponStatus.deleted.rawValue) {
                        print("it does exists")
                        self.removeSpinner()
                        self.performSegue(withIdentifier: "segueFromCouponToAccepted", sender: nil)
                    } else {
                        self.confirmCreateClientCoupon()
                    }
                } else {
                    print("Goes to create coupon")
                    self.confirmCreateClientCoupon()
                }
        }
    }
    
    func confirmCreateClientCoupon() {
        let confirmMessage = UIAlertController(title: "Confirmación", message: "¿Está seguro que desea el cupón?", preferredStyle: .alert)
        confirmMessage.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (alertAction) in
            
            self.removeSpinner()
        }))
        confirmMessage.addAction(UIAlertAction(title: "Si, Seguro", style: .default, handler: { (alertAction) in
            
            self.createClientCoupon()
        }))
        
        self.present(confirmMessage, animated: true, completion: nil)
    }
    
    func createClientCoupon() {
        let database = Database.database().reference()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let dataClientCoupon: [String: Any] = [
            "couponAvailable": self.coupon.couponAvailable!,
            "dateStatus": "",
            "expiration": self.coupon.expiration!,
            "nameCoupon": self.coupon.nameCoupon!,
            "status": CouponStatus.valid.rawValue,
            "text": self.coupon.text!,
            "totalCoupon": self.coupon.totalCoupon!,
            "uidEmployee": "",
            "urlImage": self.coupon.urlImage!
        ]
        
        database.child("clientCoupon")
        .child(uid)
        .child(self.keyCoupon)
            .setValue(dataClientCoupon) { (error, databaseReference) in
                
                if let error = error {
                    self.removeSpinner()
                    self.showMessage(title: "Error", message: "Se produjo un error inesperado Favor volver a intentar \(error.localizedDescription)")
                } else {
                    self.updateCoupon()
                }
        }
    }
    
    func updateCoupon() {
        let database = Database.database().reference()
        
        let dataCoupon: [String: Any] = [
            "couponAvailable": self.coupon.couponAvailable! - 1,
            "expiration": self.coupon.expiration!,
            "nameCoupon": self.coupon.nameCoupon!,
            "text": self.coupon.text!,
            "totalCoupon": self.coupon.totalCoupon!,
            "urlImage": self.coupon.urlImage!
        ]
        
        database.child("coupons")
            .child(self.keyCoupon)
            .setValue(dataCoupon) { (error, databaseReference) in
                self.removeSpinner()
                
                if let error = error {
                    self.showMessage(title: "Error", message: "Se produjo un error inesperado, Favor volver a intentar \(error.localizedDescription)")
                } else {
                    self.performSegue(withIdentifier: "segueFromCouponToAccepted", sender: nil)
                }
                
        }
    }
    /*
    func delayWithSeconds(_ seconds: Double, completions: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completions()
        }
    }*/
}
