//
//  CellFilterTableViewCell.swift
//  DropboxPhotoTest
//
//  Created by Rebecca Hirsch on 3/11/18.
//  Copyright © 2018 citruscircuits. All rights reserved.
//

import UIKit

class CellFilterTableViewCell: UITableViewCell {

    @IBOutlet weak var teamNum: UILabel!
    @IBOutlet weak var dataPoint: UILabel!
    @IBOutlet weak var dataValue: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
