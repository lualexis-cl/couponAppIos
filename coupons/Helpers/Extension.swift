//
//  Extension.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-18.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    func load(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        DispatchQueue.global().async { [weak self] in
            
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
        
    }
    
    func roundedCorner() {
        self.layer.cornerRadius = 15.0
    }
}

extension String {
    func stringToDate() -> Date? {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return format.date(from: self)
    }
    
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"

        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

extension Date {
    func toNow() -> Date? {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        let dateString = format.string(from: self)
        
        return format.date(from: dateString)
    }
    
    func dateToString() -> String? {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return format.string(from: self)
    }
}

fileprivate var vSpinner : UIView?

extension UIViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.large)
        ai.startAnimating()
        ai.center = spinnerView.center
        spinnerView.addSubview(ai)
        onView.addSubview(spinnerView)
        //DispatchQueue.main.async {
            
        //}
        //self.view = spinnerView
       vSpinner = spinnerView
    }
    
    func removeSpinner() {
        //DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        //}
    }
}

extension UITextField {
    func roundedCorner() {
        self.layer.cornerRadius = Constants.Numbers.cornerRadius
        self.layer.borderWidth = 1
        self.layer.masksToBounds = true
    }
}

extension UIButton {
    func roundedCorner() {
        self.layer.cornerRadius = Constants.Numbers.cornerRadius
    }
}
