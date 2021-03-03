//
//  LeaderboardTableViewCell.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 7/27/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit

class LeaderboardTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        
    } 

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var wealthLabel: UILabel!
}
