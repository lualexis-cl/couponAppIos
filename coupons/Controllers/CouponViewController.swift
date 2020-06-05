//
//  CouponViewController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-16.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SDWebImage

class CouponViewController: UIViewController {

    @IBOutlet weak var couponTableView: UITableView!
    
    var couponHash = [String: Coupon]()
    var couponKeys = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        self.couponTableView.delegate = self
        self.couponTableView.dataSource = self
        
        loadDataCoupons()
    }
    
    func loadDataCoupons() {
        self.showSpinner(onView: self.view)
        let database = Database.database().reference()
        
        database
            .child("coupons")
            .observe(.childAdded) { (snapshot) in
                
                let result = snapshot.value as? NSDictionary
                let coupon = self.dictionaryToCoupon(value: result, key: snapshot.key)
                
                self.couponHash[snapshot.key] = coupon
                self.couponKeys.insert(snapshot.key, at: 0)
                self.couponTableView.reloadData()
                self.removeSpinner()
        }
        
        database
            .child("coupons")
            .observe(.childChanged) { (snapshot) in
            
                let result = snapshot.value as? NSDictionary
                let coupon = self.dictionaryToCoupon(value: result, key: snapshot.key)
                self.couponHash[snapshot.key] = coupon
                self.couponTableView.reloadData()
                self.removeSpinner()
        }
        
        database
            .child("coupons")
            .observe(.childRemoved) { (snapshot) in
                print("Remove \(snapshot.key)")
                self.couponKeys.removeAll { $0 ==  snapshot.key }
                self.couponHash.removeValue(forKey: snapshot.key)
                
                self.couponTableView.reloadData()
                self.removeSpinner()
        }
    }
    
    func dictionaryToCoupon(value: NSDictionary?, key: String) -> Coupon {
        return Coupon(couponAvailable: value?["couponAvailable"] as? Int,
                    expiration: value?["expiration"] as? String,
                    nameCoupon: value?["nameCoupon"] as? String,
                    text: value?["text"] as? String,
                    totalCoupon: value?["totalCoupon"] as? Int,
                    urlImage: value?["urlImage"] as? String,
                    keyCoupon: key)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "segueDetailCoupon") {
            if let indexPath = self.couponTableView.indexPathForSelectedRow {
                let controller = segue.destination as! CouponDetailViewController
                let key = self.couponKeys[indexPath.row]
                let coupon = self.couponHash[key]!
                controller.keyCoupon = coupon.keyCoupon
                
                self.couponTableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
}

extension CouponViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "segueDetailCoupon", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 267
    }
}

extension CouponViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.couponHash.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellCoupons", for: indexPath) as! CouponRowTableViewCell
        
        cell.rowView.layer.cornerRadius = 15.0
        let key = self.couponKeys[indexPath.row]
        let coupon = self.couponHash[key]!
        
        cell.couponImageView.image = UIImage(named: "station")
        cell.couponNameLabel.text = coupon.nameCoupon
        let today = Date()
        
        if (coupon.couponAvailable <= 0) {
            cell.couponAvailableLabel.textColor = .red
            cell.couponAvailableLabel.text = "Cupones Agotados"
        } else if (coupon.expiration.stringToDate()! < today.toNow()!) {
            cell.couponAvailableLabel.textColor = .red
            cell.couponAvailableLabel.text = "Cupón Vencido"
        } else {
            cell.couponAvailableLabel.textColor = .black
            cell.couponAvailableLabel.text = "Cupones disponibles \(coupon.couponAvailable!) de \(coupon.totalCoupon!)"
        }
        
        cell.couponImageView.sd_setImage(with: URL(string: coupon.urlImage), placeholderImage: UIImage(named: "station"), completed: { image, error, cacheType, imageURL in

            cell.couponImageView?.roundedCorner()
        })
        
        
        return cell
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {

        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
}
