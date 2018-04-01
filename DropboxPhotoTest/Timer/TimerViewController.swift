//
//  TimerViewController.swift
//  DropboxPhotoTest
//
//  Created by Janet Liu on 2/3/18.
//  Copyright © 2018 citruscircuits. All rights reserved.
//

import UIKit
import Firebase

class TimerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var timerValue: UILabel!
    
    var timer = Timer()
    var count = 00.00
    var green = UIColor(red: 119/255, green: 218/255, blue: 72/255, alpha: 1.0)
    var red = UIColor(red: 244/255, green: 142/255, blue: 124/255, alpha: 1.0)
    var driveTime = 00.00
    var firebase = Database.database().reference()
    var ourTeam: DatabaseReference!
    var timeArray: [Float] = []
    var outcomeArray: [Bool] = []
    var didSucceed: Bool? = nil
    var timeDataKey: String?
    var outcomeDataKey: String?
    var timeLabelText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timerValue.text = self.timeLabelText
        self.table.register(UINib(nibName: "CellTimerTableViewCell", bundle: nil), forCellReuseIdentifier: "timerCell")
        self.table.delegate = self
        self.table.dataSource = self
        self.table.reloadData()
        let (m, s, ds) = convertSeconds(totalDeciSeconds: Int(count))
        startButton.layer.cornerRadius = 5
        startButton.backgroundColor = green
        timeLabel.text = timeToString(m: m, s: s, ds: ds)
        outcomeDataKey = self.timeDataKey! + "Outcome"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var cells = 0
        cells = (self.timeArray.count) ?? 0
        return cells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timerCell", for: indexPath) as! CellTimerTableViewCell
        cell.trialNumber.text = "\(String(describing: indexPath.row + 1))"
        cell.timerValue.text = "\(String(describing: self.timeArray[indexPath.row])) sec"
        cell.didSucceed.text = String(describing: self.outcomeArray[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            self.ourTeam.observeSingleEvent(of: .value, with: { (snap) in
                let timeToDelete = self.timeArray[Int(indexPath.row)]
                let index = Int(indexPath.row)
                self.timeArray.remove(at: Int(indexPath.row))
                self.removeArrayFromFirebase(dataToRemove: timeToDelete, keyToRemove: self.timeDataKey!, neededType: NeededType.Float, index: index, snap: snap)
                let outcomeToDelete = self.outcomeArray[Int(indexPath.row)]
                self.outcomeArray.remove(at: Int(indexPath.row))
                self.removeArrayFromFirebase(dataToRemove: outcomeToDelete, keyToRemove: self.outcomeDataKey!, neededType: NeededType.Bool, index: index, snap: snap)
                tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            })
        }
    }
    
    @IBAction func startButton(_ sender: AnyObject) {
        if timer.isValid {
            timer.invalidate()
            startButton.setTitle("Start", for: UIControlState.normal)
            startButton.backgroundColor = green
        } else {
            timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(TimerViewController.result), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timer, forMode: RunLoopMode.commonModes)
            startButton.setTitle("Stop", for: UIControlState.normal)
            startButton.backgroundColor = red
        }
    }
    
    @IBAction func clearButton(_ sender: AnyObject) {
        clearTimer()
    }
    
    func clearTimer() {
        timer.invalidate()
        startButton.setTitle("Start", for: UIControlState.normal)
        startButton.backgroundColor = green
        count = 0
        let (m, s, ds) = convertSeconds(totalDeciSeconds: Int(count))
        timeLabel.text = timeToString(m: m, s: s, ds: ds)
    }
    
    @objc func result() {
        count += 1
        let (m, s, ds) = convertSeconds(totalDeciSeconds: Int(count))
        timeLabel.text = timeToString(m: m, s: s, ds: ds)
    }
    
    func convertSeconds(totalDeciSeconds: Int) -> (m: Int, s: Int, ds: Int) {
        let seconds = (totalDeciSeconds / 100) % 60
        let minutes = ((totalDeciSeconds / 100) / 60)
        let deciseconds = totalDeciSeconds % 100
        return (minutes, seconds, deciseconds)
    }
    
    func timeToString(m: Int, s: Int, ds: Int) -> String {
        let m = String(format: "%02d", m)
        let s = String(format: "%02d", s)
        let ds = String(format: "%02d", ds)
        return "\(m):\(s):\(ds)"
    }
    
    func completedTrialAlert(dataKey: String) {
        if dataKey == "pitDriveTimeOutcome" {
            let driveTimerAlert = UIAlertController(title: "What was the treadmill distance travelled?", message: "", preferredStyle: .alert)
            
            driveTimerAlert.addTextField { (textField) in
                textField.keyboardType = UIKeyboardType.decimalPad
                textField.placeholder = "Enter treadmill distance (ft)"
            }
            
            driveTimerAlert.addTextField { (textField) in
                textField.keyboardType = UIKeyboardType.decimalPad
                textField.placeholder = "Enter robot length (ft)"
            }
            
            let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
                
                let distanceTravelled = (driveTimerAlert.textFields![0].text! as NSString).doubleValue
                let robotLength = (driveTimerAlert.textFields![1].text! as NSString).doubleValue
                
                if distanceTravelled > Double(7.4) - robotLength {
                    self.didSucceed = true
                    self.outcomeArray.append(true)
                    self.ourTeam.observeSingleEvent(of: .value, with: { (snap) in
                        self.writeArrayToFirebase(dataKey: dataKey, neededType: NeededType.Bool, value: self.didSucceed!, snap: snap)
                    })
                    self.viewDidLoad()
                    self.outcomeResultAlert(carpetDistance: distanceTravelled * 1.30 - robotLength * 1.30)
                } else {
                    self.didSucceed = false
                    self.outcomeArray.append(false)
                    self.ourTeam.observeSingleEvent(of: .value, with: { (snap) in
                        self.writeArrayToFirebase(dataKey: dataKey, neededType: NeededType.Bool, value: self.didSucceed!, snap: snap)
                    })
                    self.viewDidLoad()
                    self.outcomeResultAlert(carpetDistance: distanceTravelled * 1.30 - robotLength * 1.30)
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
            
            driveTimerAlert.addAction(confirmAction)
            driveTimerAlert.addAction(cancelAction)
            self.present(driveTimerAlert, animated: true, completion: nil)
        } else {
            let rampTimerAlert = UIAlertController(title: "Did the robot succeed?", message: "", preferredStyle: .alert)
            
            let didSucceedAction = UIAlertAction(title: "True", style: .default, handler: nil)
            let didFailAction = UIAlertAction(title: "False", style: .default, handler: nil)
            
            rampTimerAlert.addAction(didSucceedAction)
            rampTimerAlert.addAction(didFailAction)
            
            let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
                if didSucceedAction.isEnabled == true {
                    self.didSucceed = true
                }
                else {
                    self.didSucceed = false
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
                
            rampTimerAlert.addAction(confirmAction)
            rampTimerAlert.addAction(cancelAction)
            
            
        }
    }
    
    func outcomeResultAlert(carpetDistance: Double) {
        let confirmAction = UIAlertAction(title: "OK", style: .default) { (_) in
        }
        if self.didSucceed == true{
            let outcomeResultAlert = UIAlertController(title: "The trial was successful.", message: "The robot travelled an equivalent of \(carpetDistance) ft on the carpet.", preferredStyle: .alert)
            outcomeResultAlert.addAction(confirmAction)
            self.present(outcomeResultAlert, animated: true, completion: nil)
        } else {
            let outcomeResultAlert = UIAlertController(title: "The trial was not successful.", message: "The robot travelled an equivalent of \(carpetDistance) ft on the carpet.", preferredStyle: .alert)
            outcomeResultAlert.addAction(confirmAction)
            self.present(outcomeResultAlert, animated: true, completion: nil)
        }
    }
    
   @IBAction func submitButton(_ sender: AnyObject) {
        if startButton.currentTitle as String! == "Start" && Float(count) != 0 {
            let driveTime = Float(count) / 100
            print("number of total seconds is \(driveTime)")
            timeArray.append(driveTime)
            self.ourTeam.observeSingleEvent(of: .value, with: { (snap) in
                self.writeArrayToFirebase(dataKey: self.timeDataKey!, neededType: NeededType.Float, value: driveTime, snap: snap)
            })
            clearTimer()
            completedTrialAlert(dataKey: self.outcomeDataKey!)
        } else if count == 00.00 {
             let inputAlert = UIAlertController(title: "User Input?", message: "Please time something before submitting", preferredStyle: .alert)
            inputAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            present(inputAlert, animated: true, completion: nil)
        } else {
            self.startButton(self.startButton)
            let inputConfirmationAlert = UIAlertController(title: "Confirmation", message: "Please confirm this time before submitting to Firebase", preferredStyle: .alert)
            let affirmative = UIAlertAction(title: "Correct", style: .default) { (_) in
                self.submitButton(self.submitButton)
            }
            let negative = UIAlertAction(title: "Back", style: .default)
            inputConfirmationAlert.addAction(affirmative)
            inputConfirmationAlert.addAction(negative)
            present(inputConfirmationAlert, animated: true, completion: nil)
        }
    }
    
    func writeArrayToFirebase(dataKey: String, neededType: NeededType, value: Any, snap: DataSnapshot) {
        var currentData = snap.childSnapshot(forPath: dataKey).value as? [Any] ?? []
        currentData.append(value)
        switch neededType {
            case .Float:
                ourTeam.child(dataKey).setValue(currentData as! [Float])
            case .Bool:
                ourTeam.child(dataKey).setValue(currentData as! [Bool])
        }
    }
    
    func removeArrayFromFirebase(dataToRemove: Any, keyToRemove: String, neededType: NeededType, index: Int, snap: DataSnapshot)     {
        var currentData = snap.childSnapshot(forPath: keyToRemove).value as! [Any]
        currentData.remove(at: index)
        switch neededType {
            case .Float:
                self.ourTeam.child(keyToRemove).setValue(currentData as? [Float] ?? [])
            case .Bool:
                self.ourTeam.child(keyToRemove).setValue(currentData as? [Bool] ?? [])
        }
    }
    
    enum NeededType {
        case Float
        case Bool
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    // Do any additional setup after loading the view.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
