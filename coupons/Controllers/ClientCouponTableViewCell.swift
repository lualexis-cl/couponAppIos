//
//  ClientCouponTableViewCell.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-22.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit

class ClientCouponTableViewCell: UITableViewCell {
    
    @IBOutlet weak var rowView: UIView!
    @IBOutlet weak var couponImageView: UIImageView!
    @IBOutlet weak var couponNameLabel: UILabel!
    @IBOutlet weak var couponExpirationLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        overrideUserInterfaceStyle = .light
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
