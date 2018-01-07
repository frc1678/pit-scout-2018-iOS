//
//  TableViewController.swift
//  DropboxPhotoTest
//
//  Created by Bryton Moeller on 1/18/16.
//  Copyright © 2016 citruscircuits. All rights reserved.
//
import UIKit
import Foundation
import Firebase
import FirebaseStorage
import Haneke

let firebaseKeys = ["pitNumberOfWheels",  "pitSelectedImageName"]

class TableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    let cellReuseId = "teamCell"
    @IBAction func addTeam(_ sender: UIButton) {
        showInputDialog()
        //sleep(10)
        addATeam()
    }
    
    func addATeam() {
        if teamName != nil && teamNum != nil {
            self.teamAdder(self.teamNum!, self.teamName!)
        } else {
            print("AHHHHH WHY")
            
        }
    }
    var firebase : DatabaseReference?
    var teams = [String: [String: AnyObject]]()
    
    var scoutedTeamInfo : [[String: Int]] = []   // ["num": 254, "hasBeenScouted": 0] // data is stored in cache
    // 0 is false, 1 is true
    let operationQueue = OperationQueue()
    var teamNums = [Int]()
    var timer = Timer()
    var photoManager : PhotoManager?
    var urlsDict : [Int : NSMutableArray] = [Int: NSMutableArray]()
    var dontNeedNotification = true
    let cache = Shared.dataCache
    var refHandle = DatabaseHandle()
    var firebaseStorageRef : StorageReference?
    var teamNum : Int?
    var teamName : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsSelection = false //You can select once we are done setting up the photo uploader object
        firebaseStorageRef = Storage.storage().reference(forURL: "gs://scouting-2017-5f51c.appspot.com")
        // Get a reference to the storage service, using the default Firebase App
        // Create a storage reference from our storage service
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TableViewController.didLongPress(_:)))
        self.tableView.addGestureRecognizer(longPress)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.firebase = Database.database().reference()
        
        self.firebase!.observe(.value, with: { (snapshot) in
            self.setup(snapshot.childSnapshot(forPath: "Teams"))
        })
        
        setupphotoManager()
        
        NotificationCenter.default.addObserver(self, selector: #selector(TableViewController.updateTitle(_:)), name: NSNotification.Name(rawValue: "titleUpdated"), object: nil)
    }
    
    func updateTitle(_ note : Notification) {
        DispatchQueue.main.async { () -> Void in
            self.title = note.object as? String
        }
    }
    
    func setup(_ snap: DataSnapshot) {
        self.teams = NSMutableDictionary() as! [String : [String : AnyObject]]
        self.scoutedTeamInfo = []
        self.teamNums = []
        var td : NSDictionary?
        if let arrayTeamsDatabase = snap.value as? [NSDictionary] { // If we restore from backup, then the teams will be an array
            td = NSDictionary(objects: arrayTeamsDatabase, forKeys: Array(arrayTeamsDatabase.map { String(describing: $0["number"] as! Int) }) as [NSCopying])
        }
        updateTeams()
        let teamsDatabase: NSDictionary = td ?? snap.value as! NSDictionary
        for (_, info) in teamsDatabase {
            // teamInfo is the information for the team at certain number
            let teamInfo = info as! [String: AnyObject]
            let teamNum = teamInfo["number"] as? Int
            if teamNum != nil {
                self.teams[String(describing: teamNum!)] = teamInfo
                let scoutedTeamInfoDict = ["num": teamNum!, "hasBeenScouted": 0]
                self.scoutedTeamInfo.append(scoutedTeamInfoDict )
                self.teamNums.append(teamNum!)
            } else {
                print("No Num")
            }
        }

        self.scoutedTeamInfo.sort { (team1, team2) -> Bool in
            if team1["num"]! < team2["num"]! {
                return true
            }
            return false
        }
        
        self.tableView.reloadData()
        self.cache.fetch(key: "scoutedTeamInfo").onSuccess({ [unowned self] (data) -> () in
            let cacheScoutedTeamInfo = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String: Int]]
            var cacheTeams: [Int] = []
            var firebaseTeams: [Int] = []
            for i in 0..<cacheScoutedTeamInfo.count {
                let teamInfo = cacheScoutedTeamInfo[i]
                cacheTeams.append(teamInfo["num"]!)
            }
            for i in 0..<self.scoutedTeamInfo.count {
                let teamInfo = self.scoutedTeamInfo[i]
                firebaseTeams.append(teamInfo["num"]!)
            }
            // If the teams in the cache are the same as the teams on Firebase, use the information inside the cache to update the table view
            if Set(cacheTeams) == Set(firebaseTeams) {
                self.scoutedTeamInfo = cacheScoutedTeamInfo
            } else {
                // Some or all teams have changed on Firebase, but if there are any identical teams, we want to keep the data on that team
                let commonTeamSet = Set(cacheTeams).intersection(Set(firebaseTeams))
                var commonTeams = Array(commonTeamSet)
                firebaseTeams = firebaseTeams.filter { !commonTeams.contains($0) }
                // Appending the cached information about the common teams
                self.scoutedTeamInfo = self.scoutedTeamInfo.filter { !commonTeams.contains($0["num"]!) }
                for i in 0..<commonTeams.count {
                    // Add cached info to cacheScoutedTeamInfo
                    let teamDictionary = cacheScoutedTeamInfo.filter { $0["num"] == commonTeams[i] }
                    self.scoutedTeamInfo.append(teamDictionary[0])
                }
            }
            // Sorts the scouted teams into numerical order
            self.scoutedTeamInfo.sort {
                $0["num"]! < $1["num"]!
            }
            self.tableView.reloadData()
        })
    }
    func updateTeams() {
         print("Updating teams")
        self.cache.fetch(key: "scoutedTeamInfo").onSuccess({ [unowned self] (data) -> () in
            let cacheScoutedTeamInfo = NSKeyedUnarchiver.unarchiveObject(with: data) as! [[String: Int]]
            var cacheTeams: [Int] = []
            var firebaseTeams: [Int] = []
            for i in 0..<cacheScoutedTeamInfo.count {
                let teamInfo = cacheScoutedTeamInfo[i]
                cacheTeams.append(teamInfo["num"]!)
            }
            for i in 0..<self.scoutedTeamInfo.count {
                let teamInfo = self.scoutedTeamInfo[i]
                firebaseTeams.append(teamInfo["num"]!)
            }
            // If the teams in the cache are the same as the teams on Firebase, use the information inside the cache to update the table view
            
            if Set(cacheTeams) == Set(firebaseTeams) {
                self.scoutedTeamInfo = cacheScoutedTeamInfo
            } else {
                // Some or all teams have changed on Firebase, but if there are any identical teams, we want to keep the data on that team
                let commonTeamSet = Set(cacheTeams).intersection(Set(firebaseTeams))
                var commonTeams = Array(commonTeamSet)
                firebaseTeams = firebaseTeams.filter { !commonTeams.contains($0) }
                // Appending the cached information about the common teams
                self.scoutedTeamInfo = self.scoutedTeamInfo.filter { !commonTeams.contains($0["num"]!) }
                for i in 0..<commonTeams.count {
                    // Add cached info to cacheScoutedTeamInfo
                    let teamDictionary = cacheScoutedTeamInfo.filter { $0["num"] == commonTeams[i] }
                    self.scoutedTeamInfo.append(teamDictionary[0])
                }
            }
            // Sorts the scouted teams into numerical order
            self.scoutedTeamInfo.sort {
                $0["num"]! < $1["num"]!
            }
            self.tableView.reloadData()
        })
    }
    
    func setupphotoManager() {
        
        if self.photoManager == nil {
            self.photoManager = PhotoManager(teamsFirebase: (self.firebase?.child("Teams"))!, teamNumbers: self.teamNums)
            photoManager?.getNext(done: { (nextImage, nextKey, nextNumber, nextDate) in
                self.photoManager?.startUploadingImageQueue(photo: nextImage, key: nextKey, teamNum: nextNumber, date: nextDate)
            })
        }
        self.tableView.allowsSelection = true
    }
    
    // MARK:  UITextFieldDelegate Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 //One section is for checked cells, the other unchecked
    }
    
    func showInputDialog() {
        //Creating UIAlertController and setting title and message for the alert dialog
        let alertController = UIAlertController(title: "Enter New Team", message: "Enter the team number and name", preferredStyle: .alert)
        
        //the confirm action taking the inputs
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            
            //getting input values
            self.teamNum = Int((alertController.textFields?[0].text)!)
            self.teamName = alertController.textFields?[1].text
            self.addATeam()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        //adding textfields to our dialog box
        alertController.addTextField { (textField) in
            textField.keyboardType = UIKeyboardType.numberPad
            textField.placeholder = "Enter Team Number"
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter Team Name"
            
        
        //adding the action to dialogbox2
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        //finally presenting the dialog box
        
        self.present(alertController, animated: true, completion: nil)
        
        }
    }
    
    func teamAdder(_ teamNum: Int, _ teamName: String) {
        if !self.teamNums.contains(self.teamNum!) {
            //keyboardType = UIKeyboardType.numberPad
            firebase?.child("Teams").child(String(teamNum)).child("name").setValue(teamName)
            firebase?.child("Teams").child(String(teamNum)).child("number").setValue(Int(teamNum))
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            var numUnscouted = 0
            for teamN in self.scoutedTeamInfo {
                if teamN["hasBeenScouted"] == 0 {
                    numUnscouted += 1
                }
            }
            return numUnscouted
        } else if section == 1 {
            var numScouted = 0
            for teamN in self.scoutedTeamInfo {
                if teamN["hasBeenScouted"] == 1 {
                    numScouted += 1
                }
            }
            return numScouted
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //updateTeams()
        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseId, for: indexPath) as UITableViewCell
        cell.textLabel?.text = "Please Wait..."
        if self.scoutedTeamInfo.count == 0 { return cell }
        var text = "shouldntBeThis"
        var teamName : String = ""
        if (indexPath as NSIndexPath).section == 1 {
            // If the team has been scouted before
            let scoutedTeamNums = NSMutableArray()
            for team in self.scoutedTeamInfo {
                if team["hasBeenScouted"] == 1 {
                    scoutedTeamNums.add(team["num"]!)
                }
            }
            // Finding the team name
            for (_, team) in teams {
                let teamInfo = team as! [String : AnyObject]
                if teamInfo["number"] as! Int == scoutedTeamNums[(indexPath as NSIndexPath).row] as! Int {
                    teamName = ""
                    if teamInfo["name"] != nil{
                        teamName = String(describing: teamInfo["name"]!)
                    } else {
                        teamName = "Offseason Bot"
                    }
                    let imageURLs = teamInfo["pitAllImageURLs"] as? [String: AnyObject] ?? [String: AnyObject]()
                    let imageKeys = teamInfo["imageKeys"] as? [String: AnyObject] ?? [String: AnyObject]()
                    if imageURLs.count != imageKeys.count {
                        // 255, 102, 102
                        cell.backgroundColor = UIColor(red: 255/255, green: 153/255, blue: 153/255, alpha: 1.0)
                        cell.textLabel!.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
                    } else if imageURLs.count == 0 {
                        cell.backgroundColor =  UIColor(white: 1.0, alpha: 1.0)
                        cell.textLabel!.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
                    } else {
                        cell.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
                        if imageURLs.count != 0 && imageURLs.count == imageKeys.count {
                            cell.textLabel!.textColor = UIColor(red: 119/255, green: 218/255, blue: 72/255, alpha: 1.0)
                        }
                    }
                }
            }
            text = "\(scoutedTeamNums[(indexPath as NSIndexPath).row]) - \(teamName)"
        } else if (indexPath as NSIndexPath).section == 0 {
            let notScoutedTeamNums = NSMutableArray()
            for team in self.scoutedTeamInfo {
                if team["hasBeenScouted"] == 0 {
                    notScoutedTeamNums.add(team["num"]!)
                }
            }
            // Finding the team name
            for (_, team) in teams {
                let teamInfo = team as! NSDictionary
                let teamNum = teamInfo["number"] as! Int
                if teamNum == notScoutedTeamNums[(indexPath as NSIndexPath).row] as! Int {
                    //Offseason bots don't have team names (8671, 9971)
                    teamName = ""
                    if teamInfo["name"] != nil{
                        teamName = String(describing: teamInfo["name"]!)
                    } else {
                        teamName = "Offseason Bot"
                    }
                    let imageURLs = teamInfo["pitAllImageURLs"] as? [String: AnyObject] ?? [String: AnyObject]()
                    let imageKeys = teamInfo["imageKeys"] as? [String: AnyObject] ?? [String: AnyObject]()
                    if imageURLs.count != imageKeys.count {
                        // 255, 102, 102
                        cell.backgroundColor = UIColor(red: 255/255, green: 153/255, blue: 153/255, alpha: 1.0)
                        cell.textLabel!.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
                    } else if imageURLs.count == 0 {
                        cell.backgroundColor =  UIColor(white: 1.0, alpha: 1.0)
                        cell.textLabel!.textColor = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
                    } else {
                        cell.backgroundColor = UIColor(white: 1.0, alpha: 1.0)
                        if imageURLs.count != 0 && imageURLs.count == imageKeys.count {
                            cell.textLabel!.textColor = UIColor(red: 119/255, green: 218/255, blue: 72/255, alpha: 1.0)
                        }
                    }
                }
            }
            text = "\(notScoutedTeamNums[(indexPath as NSIndexPath).row]) - \(teamName)"
        }

        cell.textLabel?.text = "\(text)"
        
        if((indexPath as NSIndexPath).section == 1) {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
        return cell
    }
    
    func didLongPress(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.ended {
            let longPressLocation = recognizer.location(in: self.tableView)
            if let longPressedIndexPath = tableView.indexPathForRow(at: longPressLocation) {
                if let longPressedCell = self.tableView.cellForRow(at: longPressedIndexPath) {
                    // If cell is becoming unchecked
                    if longPressedCell.accessoryType == UITableViewCellAccessoryType.checkmark {
                        longPressedCell.accessoryType = UITableViewCellAccessoryType.none
                        // Pulling out the team number from the cell text
                        let cellText = (longPressedCell.textLabel?.text)!
                        let cellTextArray = cellText.components(separatedBy: " - ")
                        let teamNum: Int = Int(cellTextArray[0])!
                        let scoutedTeamInfoIndex = self.scoutedTeamInfo.index { $0["num"]! == teamNum }
                        scoutedTeamInfo[scoutedTeamInfoIndex!]["hasBeenScouted"] = 0
                    } else { // Cell is becoming checked
                        longPressedCell.accessoryType = UITableViewCellAccessoryType.checkmark
                        let cellText = (longPressedCell.textLabel?.text)!
                        let cellTextArray = cellText.components(separatedBy: " - ")
                        let teamNum: Int = Int(cellTextArray[0])!
                        let scoutedTeamInfoIndex = self.scoutedTeamInfo.index { $0["num"]! == teamNum }
                        scoutedTeamInfo[scoutedTeamInfoIndex!]["hasBeenScouted"] = 1
                    }
                    
                    self.cache.set(value: NSKeyedArchiver.archivedData(withRootObject: scoutedTeamInfo), key: "scoutedTeamInfo")
                    
                    self.tableView.reloadData()
                }
            }
        }
    }
        
    // MARK:  UITableViewDelegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Team View Segue" {
            var number = -1
            var name = ""
            let indexPath = self.tableView.indexPath(for: sender as! UITableViewCell)
            if (indexPath! as NSIndexPath).section == 1 {
                let scoutedTeamNums = NSMutableArray()
                for team in self.scoutedTeamInfo {
                    if team["hasBeenScouted"] == 1 {
                        scoutedTeamNums.add(team["num"]!)
                    }
                }
                number = scoutedTeamNums[((indexPath as NSIndexPath?)?.row)!] as! Int
                // Finding the team name
                for (_, team) in self.teams {
                    let teamInfo = team as! [String : AnyObject]
                     var teamName = ""
                    if teamInfo["number"] as! Int == number {
                        if teamInfo["name"] != nil{
                            teamName = String(describing: teamInfo["name"]!)
                        } else {
                            teamName = "Offseason Bot"
                        }
                    }
                }
            } else if (indexPath! as NSIndexPath).section == 0 {
                
                let notScoutedTeamNums = NSMutableArray()
                for team in self.scoutedTeamInfo {
                    if team["hasBeenScouted"] == 0 {
                        notScoutedTeamNums.add(team["num"]!)
                    }
                }
                number = notScoutedTeamNums[((indexPath as NSIndexPath?)?.row)!] as! Int
                // Finding the team name
                for (_, team) in self.teams {
                    let teamInfo = team as! [String : AnyObject]
                    name = ""
                    if teamInfo["number"] as! Int == number {
                        if teamInfo["name"] != nil{
                            name = teamInfo["name"] as! String
                        } else {
                            name = "Offseason Bot"
                        }
                    }
                }
            }
            let teamViewController = segue.destination as! ViewController
            
            let teamFB = self.firebase!.child("Teams").child("\(number)")
            teamViewController.ourTeam = teamFB
            teamViewController.firebase = self.firebase!
            teamViewController.number = number
            teamViewController.title = "\(number) - \(name)"
            teamViewController.photoManager = self.photoManager
            teamViewController.firebaseStorageRef = self.firebaseStorageRef
        } else if segue.identifier == "popoverSegue" {
            let popoverViewController = segue.destination
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
            if let missingDataViewController = segue.destination as? MissingDataViewController {
                self.firebase!.child("Teams").observeSingleEvent(of: .value, with: { (snap) -> Void in
                    missingDataViewController.snap = snap
                })
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.photoManager != nil {
            self.photoManager?.currentlyNotifyingTeamNumber = 0
        }
    }
    
    @IBAction func myShareButton(sender: UIBarButtonItem) {
        self.firebase?.observeSingleEvent(of: DataEventType.value, with: { (snap) -> Void in
            do {
                let theJSONData = try JSONSerialization.data(
                    withJSONObject: self.teams ,
                    options: JSONSerialization.WritingOptions())
                
                let theJSONText = NSString(data: theJSONData,
                                           encoding: String.Encoding.ascii.rawValue)
                let activityViewController = UIActivityViewController(activityItems: [theJSONText ?? ""], applicationActivities: nil)
                self.present(activityViewController, animated: true, completion: {})
            } catch {
                print(error.localizedDescription)
            }
        })
        
    }}
