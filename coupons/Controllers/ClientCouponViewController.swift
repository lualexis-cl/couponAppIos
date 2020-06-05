//
//  ClientCouponViewController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-19.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import SDWebImage

class ClientCouponViewController: UIViewController {
    var keyClientCoupons = [String]()
    var clientCouponHash = [String: ClientCoupon]()
    
    @IBOutlet weak var couponTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.couponTable.delegate = self
        self.couponTable.dataSource = self
        
        self.loadDataClientCoupon()
    }
    
    func loadDataClientCoupon() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let database = Database.database().reference()
        
        database.child("clientCoupon").child(uid)
            .observe(.childAdded) { (snapshot) in
                print("ChildAdded")
        
                let result = snapshot.value as? NSDictionary
                let clientCoupon = self.dictionaryToClientCoupon(value: result, key: snapshot.key)
                
                if (clientCoupon.status != CouponStatus.deleted.rawValue) {
                    self.keyClientCoupons.insert(snapshot.key, at: 0)
                    self.clientCouponHash[snapshot.key] = clientCoupon
                    self.couponTable.reloadData()
                }
        }
        
        database
            .child("clientCoupon")
            .child(uid)
            .observe(.childChanged) { (snapshot) in
                print("ChildChanged")
                let result = snapshot.value as? NSDictionary
                let clientCoupon = self.dictionaryToClientCoupon(value: result, key: snapshot.key)
                
                if (clientCoupon.status == CouponStatus.deleted.rawValue) {
                    self.keyClientCoupons.removeAll { $0 == snapshot.key }
                    self.clientCouponHash.removeValue(forKey: snapshot.key)
                } else {
                    self.keyClientCoupons.removeAll { $0 == snapshot.key }
                    self.keyClientCoupons.insert(snapshot.key, at: 0)
                    self.clientCouponHash[snapshot.key] = clientCoupon
                }
                
                self.couponTable.reloadData()
        }
        
        database
            .child("clientCoupon")
            .child(uid)
            .observe(.childRemoved) { (snapshot) in
                print("ChildRemoved")
                self.keyClientCoupons.removeAll { $0 == snapshot.key }
                self.clientCouponHash.removeValue(forKey: snapshot.key)
                self.couponTable.reloadData()
        }
    }

    func dictionaryToClientCoupon(value: NSDictionary?, key: String) -> ClientCoupon {
        var clientCoupon = ClientCoupon()
        clientCoupon.couponAvailable = value?["couponAvailable"] as? Int
        clientCoupon.expiration = value?["expiration"] as? String
        clientCoupon.nameCoupon = value?["nameCoupon"] as? String
        clientCoupon.text = value?["text"] as? String
        clientCoupon.totalCoupon = value?["totalCoupon"] as? Int
        clientCoupon.urlImage = value?["urlImage"] as? String
        clientCoupon.dateStatus = value?["dateStatus"] as? String
        clientCoupon.status = value?["status"] as? Int
        clientCoupon.uidEmployee = value?["uidEmployee"] as? String
        clientCoupon.keyClientCoupon = key
        
        return clientCoupon
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "segueClientCoupon") {
            if let indexPath = self.couponTable.indexPathForSelectedRow {
                let controller = segue.destination as! CouponAcceptedViewController
                let key = self.keyClientCoupons[indexPath.row]
                let clientCoupon = self.clientCouponHash[key]!
                
                controller.keyClientCoupon = clientCoupon.keyClientCoupon
                self.couponTable.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}

extension ClientCouponViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 267
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "segueClientCoupon", sender: nil)
    }
}

extension ClientCouponViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.clientCouponHash.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellClientCoupon", for: indexPath) as! ClientCouponTableViewCell
        
        cell.rowView.layer.cornerRadius = 15.0
        cell.couponImageView.roundedCorner()
        let today = Date()
        let key = self.keyClientCoupons[indexPath.row]
        let clientCoupon = self.clientCouponHash[key]!
        cell.couponNameLabel.text = clientCoupon.nameCoupon
        
        cell.couponImageView.sd_setImage(with: URL(string: clientCoupon.urlImage!), completed: nil)
        
        let expiration = clientCoupon.expiration.stringToDate()
        let days = Calendar.current.dateComponents([.day], from: today.toNow()!, to: expiration!).day
        
        if (clientCoupon.status == CouponStatus.approved.rawValue) {
            cell.couponExpirationLabel.textColor = .black
            cell.couponExpirationLabel.text = "Cupón utilizado"
        } else if (days! >= 0){
            cell.couponExpirationLabel.textColor = .black
            cell.couponExpirationLabel.text = "Expira en \(days!) días"
        } else {
            cell.couponExpirationLabel.textColor = .red
            cell.couponExpirationLabel.text = "Cupón Vencido"
        }
        
        return cell
    }
}
