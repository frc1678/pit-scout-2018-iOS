//
//  NewMissingDataViewController.swift
//  DropboxPhotoTest
//
//  Created by Rebecca Hirsch on 3/10/18.
//  Copyright © 2018 citruscircuits. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class NewMissingDataViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBAction weak var filterByKey: UIButton!
    @IBAction weak var filterByValue: UIButton!
    
    var teamsArray = [Int] = []
    var valueArray = [String] = []
    var correspondingKeys = [String] = []
    var snap : DataSnapshot? = nil{
        didSet {
            self.viewDidLoad()
        }
    }
    
    let firebaseKeys = ["pitAvailableWeight", "pitDriveTrain", "pitWheelDiameter", "pitClimberType"]
    
    let ignoreKeys = ["pitImageKeys", "pitAllImageURLs", "pitSEALsNotes", "pitDriveTest", "pitProgrammingLanguage", "pitAvailableWeight", "pitCanCheesecake", "pitSelectedImage", "pitMaxHeight", "pitSEALsNotes", "pitRampTime", "pitRampTimeOutcome", "pitDriveTime", "pitDriveTimeOutcome"]
    
    override func viewDidLoad() {
        
        
        if let snap = self.snap {
            for team in snap.children.allObjects {
                let t = (team as! DataSnapshot).value as! [String: AnyObject]
                if t["number"] != nil {
                    teamsArray.append(t["number"])
                    }
                for key in ignoreKeys {
                    valueArray.append(t["\(key)"])
                    correspondingKeys.append(key)
                }
            }
        }
    }
    
    
    func updateMissingData(_ teamNumber : Int, correspondingKey: String, value: String) {
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            var cells = 0
            cells = (self.valueArray.count) ?? 0
            return cells
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "missingDataCell", for: indexPath) as! CellTimerTableViewCell
            cell.teamNumber.text = "\(teamNumber)"
            cell.dataPoint.text = "\(dataPoint)"
            cell.value.text = "\(value)"
            return cell
        }
        
    }
}
