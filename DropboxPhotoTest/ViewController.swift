//
//  ViewController.swift
//  DropboxPhotoTest
//
//  Created by Bryton Moeller on 12/30/15.
//  Copyright © 2015 citruscircuits. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase
import FirebaseStorage
import Haneke
import MWPhotoBrowser

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIScrollViewDelegate, MWPhotoBrowserDelegate, UITextViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var addImageButton: UIButton!
    @IBOutlet weak var viewImageButton: UIButton!
    @IBOutlet weak var deleteImageButton: UIButton!
    @IBOutlet weak var availableWeightTextField: UITextField! { didSet { availableWeightTextField.delegate = self } }
    @IBOutlet weak var selectedImageTextField: UITextField! { didSet { selectedImageTextField.delegate = self } }
    @IBOutlet weak var maxHeightTextField: UITextField! { didSet { maxHeightTextField.delegate = self } }

    @IBOutlet weak var wheelDiameterSegControl: UISegmentedControl!
    @IBOutlet weak var programmingLanguageSegControl: UISegmentedControl!
    @IBOutlet weak var driveTrainSegControl: UISegmentedControl!
    @IBOutlet weak var climberTypeSegControl: UISegmentedControl!
    @IBOutlet weak var driveTestSegControl: UISegmentedControl!
    @IBOutlet weak var driveTimerButton: UIButton!
    @IBOutlet weak var rampTimerButton: UIButton!
    @IBOutlet weak var canCheesecakeSwitch: UISwitch!
    @IBOutlet weak var SEALsNotesTextView: UITextView!{ didSet { SEALsNotesTextView.delegate = self } }
    @IBAction func AutoTimerSegue(_ sender: UIButton) {
    }
  
    var driveTimeArray: [Float] = []
    var rampTimeArray: [Float] = []
    var driveOutcomeArray: [Bool] = []
    var rampOutcomeArray: [Bool] = []
   
    var green = UIColor(red: 119/255, green: 218/255, blue: 72/255, alpha: 1.0)
    var red: UIColor =  UIColor(red: 244/255, green: 142/255, blue: 124/255, alpha: 1)
    var white: UIColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
    
    
    var photoManager : PhotoManager!
    var number : Int!
    var firebase = Database.database().reference()
    var firebaseStorageRef : StorageReference!
    var ourTeam : DatabaseReference!
    var photos = [MWPhoto]()
    var canViewPhotos : Bool = true //This is for that little time in between when the photo is taken and when it has been passed over to the uploader controller.
    var numberOfImagesOnFirebase = -1
    var notActuallyLeavingViewController = false
    let teamsList = Shared.dataCache
    var deleteImagePhotoBrowser : Bool = false
    let dataKeys: [[String: NeededType]] = [["pitSelectedImage": .String], ["pitAvailableWeight": .Int], ["pitDriveTrain": .String], ["pitCanCheesecake": .Bool], ["pitSEALsNotes": .String], ["pitProgrammingLanguage": .String], ["pitClimberType": .String], ["pitMaxHeight": .Float], ["pitDriveTime": .Float], ["pitDriveTest": .String], ["pitRampTime": .Float], ["pitDriveTimeOutcome": .Bool], ["pitRampTimeOutcome": .Bool], ["pitWheelDiameter": .String]]
    
    var activeField : UITextField? {
        didSet {
            scrollPositionBeforeScrollingToTextField = scrollView.contentOffset.y
            print(scrollPositionBeforeScrollingToTextField)
            self.scrollView.scrollRectToVisible((activeField?.frame)!, animated: true)
        }
    }
    var scrollPositionBeforeScrollingToTextField : CGFloat = 0
    
    var activeView : UITextView? {
        didSet {
            scrollPositionBeforeScrollingToTextView = scrollView.contentOffset.y
            print(scrollPositionBeforeScrollingToTextView)
            self.scrollView.scrollRectToVisible((activeView?.frame)!, animated: true)
            }
        }
    var scrollPositionBeforeScrollingToTextView : CGFloat = 0
    
    
    //MARK: Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dismisses keyboard when tapping outside of keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
<<<<<<< HEAD
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: scrollPositionBeforeScrollingToTextField), animated: true)
        
        self.ourTeam.child("pitAllImageURLs").observe(.value, with: { (snap) -> Void in
            self.numberOfImagesOnFirebase = Int(snap.childrenCount)
            self.updateMyPhotos({})
        })
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
=======
>>>>>>> origin/master
        teamsList.fetch(key: "teams").onSuccess({ (keysData) in
            let keysArray = NSKeyedUnarchiver.unarchiveObject(with: keysData) as? [String]
            if keysArray == nil {
                // teamsList is the cache of keys to be placed on firebase. It is an array of strings [teamNum_date]
                self.teamsList.set(value: [String]().asData(), key: "teams")
            }
        })
        
        ourTeam.observeSingleEvent(of: .value) { (snapshot) in
            for i in snapshot.childSnapshot(forPath: "pitDriveTime").children {
                if let unwrapped = (i as! DataSnapshot).value as? Float {
                    self.driveTimeArray.append(unwrapped)
                }
            }
            for i in snapshot.childSnapshot(forPath: "pitRampTime").children {
                if let unwrapped = (i as! DataSnapshot).value as? Float {
                    self.rampTimeArray.append(unwrapped)
                }
            }
            for i in snapshot.childSnapshot(forPath: "pitDriveTimeOutcome").children {
                if let unwrapped = (i as! DataSnapshot).value as? Bool {
                    self.driveOutcomeArray.append(unwrapped)
                }
            }
            for i in snapshot.childSnapshot(forPath: "pitRampTimeOutcome").children {
                if let unwrapped = (i as! DataSnapshot).value as? Bool {
                    self.rampOutcomeArray.append(unwrapped)
                }
            }
            while self.rampOutcomeArray.count != self.rampTimeArray.count {
                if self.rampOutcomeArray.count > self.rampTimeArray.count {
                    self.rampOutcomeArray.remove(at: self.rampOutcomeArray.count-1)
                } else {
                    self.rampTimeArray.remove(at: self.rampTimeArray.count-1)
                }
            }
        }
    }
    
    enum NeededType {
        case Int
        case Float
        case Bool
        case String
    }
    
    // This function gets a UI element's current value in Firebase. It is a function that prevents initialValue from being returned, until the asynchronous Firebase observation is completed.
    func getInitialValue(dataKey: String, neededType: NeededType, done: @escaping (_ initialValue : Any?) ->()) {
        var initialValue: Any?
        self.ourTeam.observeSingleEvent(of: .value, with: { (snap) -> Void in
            
            switch neededType {
            case .Int:
                initialValue = snap.childSnapshot(forPath: dataKey).value as? Int ?? "No current value"
            case .Float:
                initialValue = snap.childSnapshot(forPath: dataKey).value as? Float ?? "No current value"
            case .Bool:
                initialValue = snap.childSnapshot(forPath: dataKey).value as? Bool ?? "No current value"
            case .String:
                if let a = snap.childSnapshot(forPath: dataKey).value as? String, snap.childSnapshot(forPath: dataKey).value as? String != "" {
                    initialValue = a
                } else {
                    initialValue = "No current value"
                }
            }
            done(initialValue)
        })
    }
    
    func setUpTextField(elementName: UITextField, dataKey: String, dataKeyIndex: Int, neededType: NeededType) {
        self.getInitialValue(dataKey: dataKey, neededType: neededType, done: { initialValue in
            self.setInitialText(textField: elementName, initialValue: initialValue!)
        })
        elementName.tag = dataKeyIndex
        elementName.addTarget(self, action: #selector(textFieldValueChanged(_:)), for: UIControlEvents.editingChanged)
    }
    
    func setUpTextView(elementName: UITextView, dataKey: String, dataKeyIndex: Int, placeHolder: String) {
        self.getInitialValue(dataKey: dataKey, neededType: .String, done: { initialValue in
            if initialValue as! String != "No current value" {
                elementName.backgroundColor = self.white
                elementName.textColor = UIColor.black
                elementName.text = String(describing: initialValue!)
            } else {
                elementName.textColor = self.white
                elementName.backgroundColor = self.red         
                elementName.text = String(describing: placeHolder)
            }
        })
        
    }
    
    func setUpSegmentedControl(elementName: UISegmentedControl, dataKey: String, dataKeyIndex: Int) {
        self.getInitialValue(dataKey: dataKey, neededType: .String, done: { initialValue in
            self.setSelectedSegment(segControl: elementName, initialValue: initialValue as! String)
        })
        elementName.tag = dataKeyIndex
        elementName.addTarget(self, action: #selector(ViewController.segmentedControlValueChanged(_:)), for: .valueChanged)
    }
    
    func setUpSwitch(elementName: UISwitch, dataKey: String, dataKeyIndex: Int) {
        self.getInitialValue(dataKey: dataKey, neededType: .Bool, done: { initialValue in
            if initialValue as? Bool == true {
                elementName.tintColor = self.green
                elementName.onTintColor = self.green
                elementName.setOn(true, animated: false)
            } else if initialValue as? String == "No current value" {
                elementName.setOn(true, animated: false)
                elementName.tintColor = self.red
                elementName.onTintColor = self.red
            } else {
                elementName.setOn(false, animated: false)
            }
        })
        elementName.tag = dataKeyIndex
        elementName.addTarget(self, action: #selector(switchValueChanged(_:)), for: UIControlEvents.valueChanged)
    }
    
    // Abstracted code to set values of UI elements. Sets background to red if there is no current value.
    func setInitialText(textField: UITextField, initialValue: Any) {
        if initialValue as? String != "No current value"{
            textField.textColor = UIColor.black
            textField.backgroundColor = self.white
            textField.text = String(describing: initialValue)
        } else {
            textField.textColor = white
            textField.backgroundColor = red
            textField.text = String(describing: initialValue)
        }
    }
    
    func setSelectedSegment(segControl: UISegmentedControl, initialValue: String) {
        if initialValue != "No current value"{
            segControl.tintColor = self.green
            for i in 0..<segControl.numberOfSegments {
                let rawSegmentTitle: String! = segControl.titleForSegment(at: i)
                if rawSegmentTitle! == (initialValue) {
                    segControl.selectedSegmentIndex = i
                    return
                }
            }
        } else {
            segControl.tintColor = red
            segControl.layer.cornerRadius = 5
            segControl.selectedSegmentIndex = UISegmentedControlNoSegment
        }
    }
    
    // Setting up viewImageButton
    @objc func didNormalTapViewImage(_ sender: UIGestureRecognizer) {
        self.deleteImagePhotoBrowser = false
        setUpPhotoBrowser()
    }
    
    //Setting up deleteImageButton
    @objc func didNormalTapDeleteImage(_ sender: UIGestureRecognizer) {
        self.deleteImagePhotoBrowser = true
        setUpPhotoBrowser()
    }
    
    @objc func textFieldValueChanged(_ textField: UITextField) {
        let dataKeyArray: [String: NeededType] = dataKeys[textField.tag]
        var dataKey: String!
        var neededType: NeededType!
        for (key, value) in dataKeyArray{
            dataKey = key
            neededType = value
        }
        var userInput = textField.text!
        if userInput == "" {
            userInput = "0"
        }
        
        switch neededType {
            
        case .Int:
            self.ourTeam.child(dataKey).setValue(Int(userInput)!)
        case .Float:
            self.ourTeam.child(dataKey).setValue(Float(userInput)!)
        case .Bool:
           self.ourTeam.child(dataKey).setValue(Bool(userInput)!)
        case .String:
            self.ourTeam.child(dataKey).setValue(userInput)
        case .none:
            print("This should never happen. Switch has case .none")
        case .some(_):
            print("This should never happen. Switch has case .some")
        }
        self.viewDidLoad()
    }
    
    @objc func segmentedControlValueChanged(_ segmentedControl: UISegmentedControl) {
        let dataKeyArray: [String: NeededType] = dataKeys[segmentedControl.tag]
        var dataKey: String!
        for (key, _) in dataKeyArray{
            dataKey = key
        }
        let userInput: String = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!
        self.ourTeam.child(dataKey).setValue(userInput)
        self.viewDidLoad()
    }
    
    @objc func switchValueChanged(_ switchElement: UISwitch) {
        let dataKeyArray: [String: NeededType] = dataKeys[switchElement.tag]
        var dataKey: String!
        for (key, _) in dataKeyArray{
            dataKey = key
        }
        var userInput: Bool
        if switchElement.isOn{
            userInput = true
        } else {
            userInput = false
        }
        self.ourTeam.child(dataKey).setValue(userInput)
        self.viewDidLoad()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Miscellaneous Notes: climber notes, possible autos, etc" {
            textView.text = ""
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == SEALsNotesTextView {
            self.ourTeam.child("pitSEALsNotes").setValue(textView.text)
        }
        textView.backgroundColor = self.white
        textView.textColor = UIColor.black
    }
    
    //MARK: Photo Browser
    
    /**
     This function makes a new photo browser for viewing photos.
     */
    // Formatting a new photo browser for viewing photos
    func makeNewBrowser (done: @escaping(_ browser: MWPhotoBrowser) -> ()) {
        var browser = MWPhotoBrowser()
        browser = MWPhotoBrowser.init(delegate: self)
        
        // browser options
        browser.displayActionButton = false; // Show action button to allow sharing, copying, etc (defaults to YES)
        browser.displayNavArrows = true; // Whether to display left and right nav arrows on toolbar (defaults to NO)
        browser.displaySelectionButtons = true; // Whether selection buttons are shown on each image (defaults to NO)
        browser.enableGrid = false; // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
        browser.autoPlayOnAppear = false; // Auto-play first video
        done(browser)
    }
    
    /** This function allows access to the camera if button is tapped once
     */
    // Normal single tap to access camera
    @objc func didNormalTapAddImage(_ sender: UIGestureRecognizer) {
        self.notActuallyLeavingViewController = true
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    //Setting up photo browser
    func setUpPhotoBrowser() {
        self.makeNewBrowser(done: { browser in
            let imageURLs = self.ourTeam.child("pitImageKeys")
            imageURLs.observeSingleEvent(of: .value, with: { (snap) -> Void in
                if snap.childrenCount == 0 {
                    // If no photos in firebase for team
                    let noImageAlert = UIAlertController(title: "No Images", message: "No photos have been taken for this team.", preferredStyle: .alert)
                    noImageAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(noImageAlert, animated: true, completion: nil)
                } else {
                    self.notActuallyLeavingViewController = true
                    // Displaying photos in photo browser
                    self.updateMyPhotos { [unowned self] in
                        let nav = UINavigationController(rootViewController: browser)
                        nav.delegate = self
                        self.present(nav, animated: true, completion: {
                            browser.reloadData()
                        })
                    }
                }
            })
        })
    }
    /**
     This function allows access to the photo library if button is long pressed.
     */
    // Long press to access photo library, not camera
    @objc func didLongTap(_ sender: UIGestureRecognizer) {
        notActuallyLeavingViewController = true
        if sender.state == .ended {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
    /**
     This function displays the photos, pulling from the cache and Firebase.
     */
    func updateMyPhotos(_ callback: @escaping ()->()) {
        ourTeam.observeSingleEvent(of: .value, with: { (snap) -> Void in
            // Pulling images from cache and firebase
            self.photos.removeAll()
            let imageKeysArray = snap.childSnapshot(forPath: "pitImageKeys").value as? [String]
            if imageKeysArray != nil {
                for i in 0..<imageKeysArray!.count {
                    let imageKey = imageKeysArray![i]
                    // Use imageKey to find corresponding image in imageCache
                    self.photoManager.imageCache.fetch(key: String(describing: imageKey)).onSuccess ({ (image) in
                        let captionedImage = MWPhoto(image: image)
                        captionedImage!.caption = "\(String(describing: imageKey))"
                        self.photos.append(captionedImage!)
                    }).onFailure({ Void in
                        // If photo doesn't exist in cache, pull from firebase
                        let imageURLs = snap.childSnapshot(forPath: "pitAllImageURLs").value as! [String]
                        // Comparing to see if the cached image key matches the firebase URL of one of the image URLs
                        for i in 0..<imageURLs.count {
                            let url = imageURLs[i]
                            let urlArray = (url).replacingOccurrences(of: "https://firebasestorage.googleapis.com/v0/b/scouting-2018-9023a.appspot.com/o/", with: "")
                            let componentArray: [String] = urlArray.components(separatedBy: ".png?")
                            let key = componentArray[0]
                            // This is the image key extracted from the image url, which will be modified to follow the format of the actual image key
                            let modifiedKey = key.replacingOccurrences(of: "%20", with: " ").replacingOccurrences(of: "%2B", with: "+")
                            if modifiedKey == imageKey {
                                // Adding the firebase image to the local cache
                                let captionedImage = MWPhoto(url: URL(string: url))
                                captionedImage!.caption = "\(modifiedKey)"
                                self.photos.append(captionedImage!)
                            }
                        }
                    })
                }
            }
        })
        callback()
    }
    
    // This function is a mandatory requirement for the MWPhotoBrowser class. Removing it will cause the code to fail build.
    func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(self.photos.count)
    }
    
    /**
     This function sets up the photo browser, and allows photo selection or deletion. Everytime a photo is selected in the photo browser, this function will run.
     */
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt, selectedChanged selected: Bool) {
        if selected {
            if self.deleteImagePhotoBrowser == false {
                // Since deleteImagePhotoBrowser is false, the user must be in the photo browser to view images - they want to set the selected image
                self.dismiss(animated: true, completion: nil)
                ourTeam.child("pitImageKeys").observeSingleEvent(of: .value, with: { (snap) -> Void in
                    let imageKeys = snap.value as! [String]
                    for i in 0..<imageKeys.count {
                        let key = imageKeys[i]
                        if photoBrowser.photo(at: index).caption?() != nil {
                            if key == photoBrowser.photo(at: index).caption!() {
                                self.selectedImageTextField.text = key
                                self.ourTeam.child("pitSelectedImage").setValue(key)
                            }
                        }
                    }
                })
            } else {
                self.dismiss(animated: true, completion: nil)
                // Deleting images from firebase database, but not from firebase storage
                ourTeam.observeSingleEvent(of: .value, with: { (snap) -> Void in
                    let imageKeys = snap.childSnapshot(forPath: "pitImageKeys").value as! [String]
                    let caption = photoBrowser.photo(at: index).caption!()
                    for i in 0..<imageKeys.count {
                        let date = imageKeys[i]
                        if date == caption {
                            // Removing photo from image cache
                            self.photoManager.imageCache.remove(key: date)
                            self.removeArrayFromFirebase(dataToRemove: date, keyToRemove: "pitImageKeys", snap: snap)
                            let currentSelectedImageName = snap.childSnapshot(forPath: "pitSelectedImage").value as? String
                            // If deleted image is also selected image, delete key value on firebase
                            if currentSelectedImageName == date {
                                self.ourTeam.child("pitSelectedImage").removeValue()
                            }
                            // Deletes image URL from pitAllImageURLs
                            let imageURLs = snap.childSnapshot(forPath: "pitAllImageURLs").value as? [String]
                            if imageURLs != nil {
                                for i in 0..<imageURLs!.count {
                                    let url = imageURLs![i]
                                    let modifiedURL: String = url.replacingOccurrences(of: "%20", with: " ").replacingOccurrences(of: "%2B", with: "+")
                                    if modifiedURL.contains(caption!) {
                                        self.removeArrayFromFirebase(dataToRemove: url, keyToRemove: "pitAllImageURLs", snap: snap)
                                    }
                                }
                            }
                            self.teamsList.fetch(key: "teams").onSuccess({ (keysData) in
                                // Deleting from the keys cache
                                self.photoManager.backgroundQueue.async {
                                    var keysArray = NSKeyedUnarchiver.unarchiveObject(with: keysData) as! NSArray as! [String]
                                    //If there's anything in the cache, check to see if the image key exists. If it does, remove the image key from the cache
                                    if keysArray.count != 0{
                                        for i in 0..<keysArray.count-1 {
                                            if keysArray[i] == caption {
                                                keysArray.remove(at: i)
                                            }
                                        }
                                    }
                                let keysData = NSKeyedArchiver.archivedData(withRootObject: keysArray)
                                self.teamsList.set(value: keysData, key: "teams")
                                }
                            })
                        }
                    }
                })
            }
        }
    }
    
    func removeArrayFromFirebase(dataToRemove: String, keyToRemove: String, snap: DataSnapshot) {
        var currentData = snap.childSnapshot(forPath: keyToRemove).value as! [String]
        for i in 0..<currentData.count {
            if currentData[i] == dataToRemove {
                currentData.remove(at: i)
                break
            }
        }
        self.ourTeam.child(keyToRemove).setValue(currentData)
    }
    
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        return self.photos[Int(index)]
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        notActuallyLeavingViewController = true
        canViewPhotos = false
        picker.dismiss(animated: true, completion: nil)
        self.photos.append(MWPhoto(image: image))
        photoManager.photoSaver.saveImage(image)
        photoManager.addToFirebaseStorageQueue(image: image, number: number)
    }
    //You shold only have to call this once each time the app wakes up
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { // So that the scroll view can scroll so you can see the text field you are editing
        textField.resignFirstResponder()
        return true
    }
    
    func textViewShouldReturn(_ textView: UITextView) -> Bool { // So that the scroll view can scroll so you can see the text view you are editing
        textView.resignFirstResponder()
        return true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // To recognize different types of taps on addImageButton
        let normalTapGestureAddImage = UITapGestureRecognizer(target: self, action: #selector(ViewController.didNormalTapAddImage(_:)))
        let longGestureAddImage = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.didLongTap(_:)))
        addImageButton.addGestureRecognizer(normalTapGestureAddImage)
        addImageButton.addGestureRecognizer(longGestureAddImage)
        addImageButton.layer.cornerRadius = 5
        
        // To set up image browser on viewImageButton
        let normalTapGestureViewImage = UITapGestureRecognizer(target: self, action: #selector(ViewController.didNormalTapViewImage(_:)))
        viewImageButton.addGestureRecognizer(normalTapGestureViewImage)
        viewImageButton.layer.cornerRadius = 5
        
        // To set up image browser on deleteImageButton
        let normalTapGestureDeleteImage = UITapGestureRecognizer(target: self, action: #selector(ViewController.didNormalTapDeleteImage(_:)))
        deleteImageButton.addGestureRecognizer(normalTapGestureDeleteImage)
        deleteImageButton.layer.cornerRadius = 5
        driveTimerButton.layer.cornerRadius = 5
        rampTimerButton.layer.cornerRadius = 5
        
        // Setting up all the other UI elements
        self.setUpTextField(elementName: availableWeightTextField, dataKey: "pitAvailableWeight", dataKeyIndex: 1, neededType: NeededType.Int)
        
        self.setUpTextField(elementName: selectedImageTextField, dataKey: "pitSelectedImage", dataKeyIndex: 0, neededType: NeededType.String)
        
        self.setUpTextField(elementName: maxHeightTextField, dataKey: "pitMaxHeight", dataKeyIndex: 7, neededType: NeededType.Float)
        
        self.setUpSegmentedControl(elementName: wheelDiameterSegControl, dataKey: "pitWheelDiameter", dataKeyIndex: 13)
        
        self.setUpSegmentedControl(elementName: programmingLanguageSegControl, dataKey: "pitProgrammingLanguage", dataKeyIndex: 5)
        
        self.setUpSegmentedControl(elementName: driveTrainSegControl, dataKey: "pitDriveTrain", dataKeyIndex: 2)
        
        self.setUpSegmentedControl(elementName: driveTestSegControl, dataKey: "pitDriveTest", dataKeyIndex: 9)
        
        self.setUpSegmentedControl(elementName: climberTypeSegControl, dataKey: "pitClimberType", dataKeyIndex: 6)
        
        self.setUpSwitch(elementName: canCheesecakeSwitch, dataKey: "pitCanCheesecake", dataKeyIndex: 3)
        
        self.setUpTextView(elementName: SEALsNotesTextView, dataKey: "pitSEALsNotes", dataKeyIndex: 4, placeHolder: "Miscellaneous Notes: climber notes, possible autos, etc")
        SEALsNotesTextView.delegate = self
        notActuallyLeavingViewController = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "driveTimeSegue" {
            if let dest = segue.destination as? TimerViewController {
                dest.ourTeam = self.ourTeam
                dest.timeArray = self.driveTimeArray
                dest.outcomeArray = self.driveOutcomeArray
                dest.title = "Drive Timer"
                dest.timeDataKey = "pitDriveTime"
                dest.timeLabelText = "Drive Time"
            }
        } else if segue.identifier == "rampTimeSegue" {
            if let dest = segue.destination as? TimerViewController {
                dest.ourTeam = self.ourTeam
                dest.timeArray = self.rampTimeArray
                dest.outcomeArray = self.rampOutcomeArray
                dest.title = "Ramp Timer"
                dest.timeDataKey = "pitRampTime"
                dest.timeLabelText = "Ramp Time"
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
}



extension Dictionary {
    var vals : [AnyObject] {
        var v = [AnyObject]()
        for (_, value) in self {
            v.append(value as AnyObject)
        }
        return v
    }
    var keys : [AnyObject] {
        var k = [AnyObject]()
        for (key, _) in self {
            k.append(key as AnyObject)
        }
        return k
    }
    var FIRJSONString : String {
        var JSONString = "{\n"
        for i in 0..<self.keys.count {
            JSONString.append(keys[i] as! String)
            JSONString.append(" : ")
            JSONString.append(String(describing: vals[i]))
            JSONString.append("\n")
        }
        JSONString.append("}")
        return JSONString
    }
}

extension Array : DataConvertible, DataRepresentable {
    
    public typealias Result = Array
    
    public static func convertFromData(_ data:Data) -> Result? {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? Array
    }
    
    public func asData() -> Data! {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
}
