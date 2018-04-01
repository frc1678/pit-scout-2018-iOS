//
//  MissingDataTableViewController.swift
//  DropboxPhotoTest
//
//  Created by Rebecca Hirsch on 3/28/18.
//  Copyright © 2018 citruscircuits. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import DropDown

class MissingDataViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var nilDataTable: UITableView!
    @IBOutlet weak var dataPointButton: UIButton!
    @IBOutlet weak var dataPointLabel: UILabel!
    
    let dataPointDropDown = DropDown()
    var pitDataPoints: [String] = ["pitSelectedImage", "pitAvailableWeight", "pitDriveTrain", "pitProgrammingLanguage", "pitClimberType", "pitWheelDiameter", "pitRobotLength", "pitRobotWidth", "pitHasCamera"]
    var firebase: DatabaseReference?
    var teamsDictionary: NSDictionary = [:]
    // Holds firebase data from "Teams"
    var missingData: [(Int,String)] = [(Int,String)]()
    // Holds team and missing dataPoints ex. [(118, "pitClimberType \n pitProgrammingLanguage"), (100, "pitHasCamera")]
    var selectedPitDataPoint: String = "nothingShouldBeSelected"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nilDataTable.register(UINib(nibName: "MissingDataTableViewCell", bundle: nil), forCellReuseIdentifier: "missingDataCell")
        self.firebase = Database.database().reference()
        self.nilDataTable.delegate = self
        self.nilDataTable.dataSource = self
        self.firebase!.child("Teams").observe(.value) { (snap) in
            self.teamsDictionary = snap.value as! NSDictionary
            self.getNils()
        }
        self.setUpDataPointDropDown(anchorButton: dataPointButton, dataArray: pitDataPoints)
    }
    
    func getNils() {
        for (_, teamData) in self.teamsDictionary {
            var missingDataForTeam = ""
            let dataDictionary = teamData as! NSDictionary
            let num: Int? = dataDictionary.object(forKey: "number") as? Int
            // Get teamNum
            if num != nil {
                for i in pitDataPoints {
                    let value = dataDictionary.object(forKey: i)
                    if value == nil {
                        missingDataForTeam += "\(i) "
                    }
                }
                missingData.append((num!, missingDataForTeam))
            } else {
                print("This should never happen. There is a team without a number?!?")
            }
        }
        missingData.sort {$0.0 < $1.0}
        self.nilDataTable.reloadData()
    }
    
    func setUpDataPointDropDown(anchorButton: UIButton, dataArray: [String]) {
        dataPointDropDown.anchorView = anchorButton
        dataPointDropDown.bottomOffset = CGPoint(x: 0, y: anchorButton.bounds.height)
        dataPointDropDown.dataSource = dataArray
        dataPointDropDown.selectionAction = { [weak self] (index: Int, item: String) in
            self!.dataPointLabel.text = item
            self!.selectedPitDataPoint = item
            let dataPoint = self!.pitDataPoints[index]
            self!.nilDataTable.reloadData()
        }
    }
    
    @IBAction func dataPointButtonPressed(_ sender: Any) {
        dataPointDropDown.show()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let cells = missingData.count
        return cells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "missingDataCell", for: indexPath) as! MissingDataTableViewCell
        cell.missingDataPoints.text = "\(missingData[indexPath.row].1)"
        cell.teamNum.text = "\(missingData[indexPath.row].0)"
        if cell.missingDataPoints.text!.contains(selectedPitDataPoint) {
            cell.backgroundColor = UIColor(red: 255/255, green: 153/255, blue: 153/255, alpha: 1.0)
        } else {
            cell.backgroundColor = UIColor.white
        }
        return cell
    }
    
    // When the cell gets pressed
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.performSegue(withIdentifier: "TeamViewSegue", sender: tableView.cellForRow(at: indexPath))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? ViewController {
            let selectedCell = sender as! MissingDataTableViewCell
            let teamNum = Int(selectedCell.teamNum.text!)
            let teamDictionary = teamsDictionary.object(forKey: String(describing: teamNum!)) as! NSDictionary
            let teamName = teamDictionary.object(forKey: "name")
            dest.ourTeam = self.firebase!.child("Teams").child("\(teamNum!)")
            dest.number = teamNum
            dest.title = "\(teamNum!) - \(teamName!)"
        }
    }
}
