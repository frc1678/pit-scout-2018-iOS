//
//  CellMissingDataTableViewCell.swift
//  DropboxPhotoTest
//
//  Created by Rebecca Hirsch on 3/10/18.
//  Copyright © 2018 citruscircuits. All rights reserved.
//

import UIKit

class CellMissingDataTableViewCell: UITableViewCell {

    @IBOutlet weak var teamNumber: UILabel!
    @IBOutlet weak var dataPoint: UILabel!
    @IBOutlet weak var value: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
