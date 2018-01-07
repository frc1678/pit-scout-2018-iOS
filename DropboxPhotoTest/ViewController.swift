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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIScrollViewDelegate, MWPhotoBrowserDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var bottomScrollViewConstraint: NSLayoutConstraint!
    
    var photoManager : PhotoManager!
    var number : Int!
    var firebase = Database.database().reference()
    var firebaseStorageRef : StorageReference!
    var ourTeam : DatabaseReference!
    var photos = [MWPhoto]()
    var canViewPhotos : Bool = true //This is for that little time in between when the photo is taken and when it has been passed over to the uploader controller.
    var numberOfImagesOnFirebase = -1
    var notActuallyLeavingViewController = false
    let selectedImageName = PSUITextInputViewController()
    let teamsList = Shared.dataCache
    var deleteImagePhotoBrowser : Bool = false
    
    var activeField : UITextField? {
        didSet {
            scrollPositionBeforeScrollingToTextField = scrollView.contentOffset.y
            print(scrollPositionBeforeScrollingToTextField)
            self.scrollView.scrollRectToVisible((activeField?.frame)!, animated: true)
        }
    }
    var scrollPositionBeforeScrollingToTextField : CGFloat = 0
    
    //MARK: Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Dismisses keyboard when tapping outside of keyboard
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        self.ourTeam.observeSingleEvent(of: .value, with: { (snap) -> Void in //Updating UI
            
            //Adding/Viewing/Deleting Images Buttons
            let screenWidth = Int(self.view.frame.width) // Width is screenWidth-160 to give a buffer of 80 on either side
            let addImageButton = PSUIButton(title: "Add Image", width: screenWidth-160, y: 0, buttonPressed: { (sender) -> () in
                self.notActuallyLeavingViewController = true
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            })
            
            var verticalPlacement : CGFloat = addImageButton.frame.origin.y + addImageButton.frame.height
            
            let longPressImageButton = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.didLongPressImageButton(_:)))
            addImageButton.addGestureRecognizer(longPressImageButton)
            
            self.scrollView.addSubview(addImageButton)
            
            let viewImagesButton = PSUIButton(title: "View Images", width: screenWidth-160, y: Int(verticalPlacement), buttonPressed: { (sender) -> () in
                self.makeNewBrowser(done: { browser in
                    let imageURLs = self.ourTeam.child("imageKeys")
                    imageURLs.observeSingleEvent(of: .value, with: { (snap) -> Void in
                        if snap.childrenCount == 0 {
                            // If no photos in firebase cache for team
                            let noImageAlert = UIAlertController(title: "No Images", message: "No photos have been taken for this team.", preferredStyle: UIAlertControllerStyle.alert)
                            noImageAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                            self.present(noImageAlert, animated: true, completion: nil)
                        } else {
                            self.deleteImagePhotoBrowser = false
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
            })
            
            verticalPlacement = viewImagesButton.frame.origin.y + viewImagesButton.frame.height
            
            self.scrollView.addSubview(viewImagesButton)
            
            let deleteImagesButton = PSUIButton(title: "Delete Images", width: screenWidth-160, y: Int(verticalPlacement), buttonPressed: { (sender) -> () in
                self.makeNewBrowser(done: { browser in
                    let imageURLs = self.ourTeam.child("imageKeys")
                    imageURLs.observeSingleEvent(of: .value, with: { (snap) -> Void in
                        // If there are no photos in firebase cache for team
                        if snap.childrenCount == 0 {
                            let noImageAlert = UIAlertController(title: "No Images", message: "Firebase has no images for this team.", preferredStyle: UIAlertControllerStyle.alert)
                            noImageAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                            self.present(noImageAlert, animated: true, completion: nil)
                        } else {
                            self.deleteImagePhotoBrowser = true
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
            })
            
            verticalPlacement = deleteImagesButton.frame.origin.y + deleteImagesButton.frame.height
            
            self.scrollView.addSubview(deleteImagesButton)
            
            // Text Field
            self.selectedImageName.setup("Selected Image:", firebaseRef: self.ourTeam.child("pitSelectedImageName"), initialValue: snap.childSnapshot(forPath: "pitSelectedImageName").value as? String)
            self.selectedImageName.neededType = .string
            
            //Segmented Control
            let programmingLanguage = PSUISegmentedViewController()
            programmingLanguage.setup("Programming Language:", firebaseRef: self.ourTeam.child("pitProgrammingLanguage"), initialValue: snap.childSnapshot(forPath: "pitProgrammingLanguage").value)
            programmingLanguage.segments = ["Java", "C++", "Labview", "Other"]
            programmingLanguage.neededType = .string
            
            // Switch
            let driveTrain = PSUISegmentedViewController()
            driveTrain.setup("Drive Train:", firebaseRef: self.ourTeam.child("pitDriveTrain"), initialValue: snap.childSnapshot(forPath: "pitDriveTrain").value)
            driveTrain.segments = ["Tank Drive", "Swerve", "Mecanum", "Other"]
            driveTrain.neededType = .string
            
            // Text Field
            let availableWeight = PSUITextInputViewController()
            availableWeight.setup("Available Weight:", firebaseRef: self.ourTeam.child("pitAvailableWeight"), initialValue: snap.childSnapshot(forPath: "pitAvailableWeight").value)
            availableWeight.neededType = .int
            
            // Switch
            let willCheesecake = PSUISwitchViewController()
            willCheesecake.setup("Will Cheesecake", firebaseRef: self.ourTeam.child("pitDidDemonstrateCheesecakePotential"), initialValue: snap.childSnapshot(forPath: "pitDidDemonstrateCheesecakePotential").value)
    
            // SEALS Textfield
            let SEALSNotes = PSUITextInputViewController()
            SEALSNotes.setup("SEALS Notes:", firebaseRef: self.ourTeam.child("SEALSNotes"), initialValue: snap.childSnapshot(forPath: "SEALSNotes   ").value)
            
            self.addChildViewController(self.selectedImageName)
            self.addChildViewController(programmingLanguage)
            self.addChildViewController(driveTrain)
            self.addChildViewController(availableWeight)
            self.addChildViewController(willCheesecake)
            self.addChildViewController(SEALSNotes)
            
            // UI Elements
            for childViewController in self.childViewControllers {
                self.scrollView.addSubview(childViewController.view)
                childViewController.view.frame.origin.y = verticalPlacement
                
                let width = NSLayoutConstraint(item: childViewController.view, attribute: NSLayoutAttribute.width, relatedBy: .equal, toItem: self.scrollView, attribute: .width, multiplier: 1.0, constant: 0)
                let center = NSLayoutConstraint(item: childViewController.view, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: self.scrollView, attribute: .centerX, multiplier: 1.0, constant: 0)
                
                self.scrollView.addConstraints([width, center])
                print(verticalPlacement)
                verticalPlacement = childViewController.view.frame.origin.y + childViewController.view.frame.height
            }
        })
        
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: scrollPositionBeforeScrollingToTextField), animated: true)
        
        self.ourTeam.child("pitAllImageURLs").observe(.value, with: { (snap) -> Void in
            self.numberOfImagesOnFirebase = Int(snap.childrenCount)
            self.updateMyPhotos({})
        })
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        teamsList.fetch(key: "teams").onSuccess({ (keysData) in
            let keysArray = NSKeyedUnarchiver.unarchiveObject(with: keysData) as? [String]
            if keysArray == nil {
                // teamsList is the cache of keys to be placed on firebase. It is an array of strings [teamNum_date]
                self.teamsList.set(value: [String]().asData(), key: "teams")
            }
        })
    }
    
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
    
    //MARK: Photo Browser
    
    /**
     This function allows access to the photo library if button is long pressed.
     */
    // Long press to access photo library, not camera
    func didLongPressImageButton(_ recognizer: UIGestureRecognizer) {
        notActuallyLeavingViewController = true
        if recognizer.state == UIGestureRecognizerState.ended {
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
            let imageKeysArray = snap.childSnapshot(forPath: "imageKeys").value as? NSDictionary
            if imageKeysArray != nil {
                for imageKey in imageKeysArray!.allValues {
                    // Use imageKey to find corresponding image in imageCache
                    self.photoManager.imageCache.fetch(key: String(describing: imageKey)).onSuccess ({ (image) in
                        let captionedImage = MWPhoto(image: image)
                        captionedImage!.caption = "\(String(describing: imageKey))"
                        self.photos.append(captionedImage!)
                    }).onFailure({ Void in
                        // If photo doesn't exist in cache, pull from firebase
                        let imageURLs = snap.childSnapshot(forPath: "pitAllImageURLs").value as? NSDictionary
                        if imageURLs != nil {
                            // Comparing to see if the cached image key matches the firebase URL of one of the image URLs
                            for url in imageURLs!.allValues {
                                let urlArray = (url as! String).replacingOccurrences(of: "https://firebasestorage.googleapis.com/v0/b/scouting-2017-5f51c.appspot.com/o/", with: "")
                                let componentArray: [String] = urlArray.components(separatedBy: ".png?")
                                let key = componentArray[0]
                                // This is the image key extracted from the image url, which will be modified to follow the format of
                                let modifiedKey = key.replacingOccurrences(of: "%20", with: " ").replacingOccurrences(of: "%2B", with: "+")
                                if modifiedKey == imageKey as! String {
                                    // Adding the firebase image to the local cache
                                    let captionedImage = MWPhoto(url: URL(string: url as! String))
                                    captionedImage!.caption = "\(modifiedKey)"
                                    self.photos.append(captionedImage!)
                                }
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
                ourTeam.child("imageKeys").observeSingleEvent(of: .value, with: { (snap) -> Void in
                    let imageKeysDict = snap.value as! NSDictionary
                    for key in imageKeysDict.allValues {
                        //MAY FIX
                        if photoBrowser.photo(at: index).caption?() != nil {
                            if key as! String == photoBrowser.photo(at: index).caption!() {
                                self.selectedImageName.set(key as! String)
                                self.ourTeam.child("pitSelectedImageName").setValue(key as! String)
                            }
                        }
                    }
                })
            } else {
                self.dismiss(animated: true, completion: nil)
                // Deleting images from firebase database, but not from firebase storage
                ourTeam.observeSingleEvent(of: .value, with: { (snap) -> Void in
                    let imageKeysDict = snap.childSnapshot(forPath: "imageKeys").value as! NSDictionary
                    let caption = photoBrowser.photo(at: index).caption!()
                    for (key, date) in imageKeysDict {
                        if date as? String == caption {
                            // Removing photo from image cache
                            self.photoManager.imageCache.remove(key: date as! String)
                            self.ourTeam.child("imageKeys").child(key as! String).removeValue()
                            let currentSelectedImageName = snap.childSnapshot(forPath: "pitSelectedImageName").value as? String
                            // If deleted image is also selected image, delete key value on firebase
                            if currentSelectedImageName == date as? String {
                                self.ourTeam.child("pitSelectedImageName").removeValue()
                            }
                            // Deletes image URL from pitAllImageURLs
                            let imageURLDictionary = snap.childSnapshot(forPath: "pitAllImageURLs").value as? [String: String]
                            if imageURLDictionary != nil {
                                for (key, url) in imageURLDictionary! {
                                    let modifiedURL: String = url.replacingOccurrences(of: "%20", with: " ").replacingOccurrences(of: "%2B", with: "+")
                                    if modifiedURL.contains(caption!){
                                        self.ourTeam.child("pitAllImageURLs").child(key).removeValue()
                                    }
                                }
                            }
                            self.teamsList.fetch(key: "teams").onSuccess({ (keysData) in
                                // Deleting from the keys cache
                                self.photoManager.backgroundQueue.async {
                                    var keysArray = NSKeyedUnarchiver.unarchiveObject(with: keysData) as! NSArray as! [String]
                                    for i in 0..<keysArray.count-1 {
                                        if keysArray[i] == caption {
                                            keysArray.remove(at: i)
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
    
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        return self.photos[Int(index)]
    }
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
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
    
    func textFieldDidBeginEditing(_ textField: UITextField)
    {
        activeField = textField
    }
    
    func adjustInsetForKeyboardShow(_ show: Bool, notification: NSNotification) {
        guard let value = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue else { return }
        let keyboardFrame = value.cgRectValue
        let adjustmentHeight = (keyboardFrame.height + 20) * (show ? 1 : -1)
        scrollView.contentInset.bottom += adjustmentHeight
        scrollView.scrollIndicatorInsets.bottom += adjustmentHeight
    }
    
    func keyboardWillShow(_ notification: NSNotification){
        adjustInsetForKeyboardShow(true, notification: notification)
    }
    func keyboardWillHide(_ notification: NSNotification){
        adjustInsetForKeyboardShow(true, notification: notification)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*func isNull(_ object: AnyObject?) -> Bool {
        if object_getClass(object) == object_getClass(NSNull()) {
            return true
        }
        return false
    }*/
    
    override var shouldAutorotate : Bool {
        return false
    }
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        notActuallyLeavingViewController = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        /*
        //If you are leaving the view controller, and only have one image, make that the selected one.
        super.viewWillDisappear(animated)
        self.photoManager.getSharedURLsForTeam(self.number) { (urls) -> () in
            if urls?.count == 1 {
                self.ourTeam.observeSingleEvent(of: .value, with: { (snap) -> Void in
                    let imageKeys = snap.childSnapshot(forPath: "imageKeys").value as! NSDictionary
                    for value in imageKeys.allValues {
                        var modifiedURL = urls![0] as! String
                        modifiedURL = modifiedURL.replacingOccurrences(of: "%20", with: " ").replacingOccurrences(of: "%2B", with: "+")
                        if modifiedURL.contains(value as! String) {
                            self.selectedImageName.set(value as AnyObject)
                        }
                    }
                })
            }
        } */
        
        self.ourTeam.observeSingleEvent(of: .value, with: { (snap) -> Void in
            //If cheescake not selected, automatically make it false
            if snap.childSnapshot(forPath: "pitDidDemonstrateCheesecakePotential").value as? Bool == nil {
                self.ourTeam.child("pitDidDemonstrateCheesecakePotential").setValue(false)
            }
            let imageKeys = snap.childSnapshot(forPath: "imageKeys").value as? [String]
            if imageKeys != nil {
                if imageKeys!.count == 1 {
                    self.ourTeam.child("pitSelectedImageName").setValue(imageKeys![0])
                }
            }
        })
    }
    
    func dismissKeyboard() {
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
        //if self.keys[0] as? String != nil && self.vals[0] as? String != nil {
        var JSONString = "{\n"
        for i in 0..<self.keys.count {
            JSONString.append(keys[i] as! String)
            JSONString.append(" : ")
            JSONString.append(String(describing: vals[i]))
            JSONString.append("\n")
        }
        JSONString.append("}")
        return JSONString
        /*} else {
         return "Not of Type [String: String], so cannot use FIRJSONString."
         }*/
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
