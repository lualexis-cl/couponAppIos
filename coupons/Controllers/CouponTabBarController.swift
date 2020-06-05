//
//  CouponTabBarController.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-18.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit
import FirebaseAuth

class CouponTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        var controllers = self.viewControllers
        
        let currentUser = Auth.auth().currentUser
        
        currentUser?.reload(completion: { (error) in
            if let error = error {
                print("Error en traer el UID \(error.localizedDescription)")
            } else {
                print("User")
                
            }
        })
        
        
        print("Uid " + (currentUser?.uid ?? ""))
        if (currentUser == nil) {
            controllers?.remove(at: 1)
            controllers?.remove(at: 2)
        } else {
            controllers?.remove(at: 2)
        }
   
        self.viewControllers = controllers
    }
    

}
