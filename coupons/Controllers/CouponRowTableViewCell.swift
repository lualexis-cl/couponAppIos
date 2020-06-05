//
//  CouponRowTableViewCell.swift
//  coupons
//
//  Created by Luis Arredondo Andrade on 2020-05-16.
//  Copyright © 2020 Luis Arredondo Andrade. All rights reserved.
//

import UIKit

class CouponRowTableViewCell: UITableViewCell {
    @IBOutlet weak var rowView: UIView!
    @IBOutlet weak var couponImageView: UIImageView!
    @IBOutlet weak var couponNameLabel: UILabel!
    @IBOutlet weak var couponAvailableLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        overrideUserInterfaceStyle = .light
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
