//
//  PhotoUploader.swift
//  DropboxPhotoTest
//
//  Created by Bryton Moeller on 2/8/16.
//  Copyright © 2018 citruscircuits. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage
import Haneke

class PhotoManager : NSObject {
    // Creates a shared instance of PhotoManager that can be used across all view controllers. Makes PhotoManager a singleton.
    static let sharedPhotoManagerInstance = PhotoManager()
    // Cache of urls used to set up images to view or delete
    let cache = Shared.dataCache
    var mayKeepWorking = true {
        didSet {
            print("mayKeepWorking: \(mayKeepWorking)")
        }
    }
    
    var timer : Timer = Timer()
    var teamsFirebase : DatabaseReference = Database.database().reference().child("Teams")
    var numberOfPhotosForTeam = [Int: Int]()
    let firebaseImageDownloadURLBeginning = "https://firebasestorage.googleapis.com/v0/b/scouting-2018-9023a.appspot.com/o/"
    let firebaseImageDownloadURLEnd = "?alt=media"
    // teamsList is a cache of keys used to find photos from the imageCache which will then be uploaded to firebase
    var teamsList = Shared.dataCache
    let imageCache = Shared.imageCache
    let firebaseStorageRef = Storage.storage().reference(forURL: "gs://scouting-2018-9023a.appspot.com/")
    var teamKeys : [String]?
    var keyIndex : Int = 0
    var backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
    
    //MARK: Setup
    
    /**
     This function makes the code sleep, measured in seconds.
     */
    func photoManagerSleep(time: Int) {
        print("Photo Manager is tired, going to take a nap for \(time) seconds.")
        sleep(UInt32(time))
        print("Ahh... that felt good. Photo Manager is awake and ready to MANAGE!!!!!")
    }
    
    /**
     This function gets all the URLs in Firebase under "pitAllImageURLs".
     */
    // Gets all the urls in firebase for a team
    func getSharedURLsForTeam(_ num: Int, fetched: @escaping (NSMutableArray?)->()) {
        if self.mayKeepWorking {
            teamsFirebase.child("\(num)").child("pitAllImageURLs").observeSingleEvent(of: .value , with: { (updateURL) in
                if let urlsArray = updateURL.value as? [String] {
                    fetched(urlsArray as! NSMutableArray)
                } else {
                    fetched(nil)
                }
            })
        }
    }
    
    /**
     This function makes the file name for the photo on Firebase Storage.
     */
    func makeFilenameForTeamNumAndIndex(_ teamNum: Int, date: String) -> String {
        return String(teamNum) + "_" + date + ".png"
    }
    
    //MARK: Uploading Photos
    
    /**
     This function is the master function behind uploading photos.
     */
    func startUploadingImageQueue(photo: UIImage, key: String, teamNum: Int, date: String) {
        // Uploads images to firebase
        self.backgroundQueue.async {
            self.storeOnFirebase(number: teamNum, date: date, image: photo, done: { didSucceed in
                if didSucceed {
                    self.removeFromCache(key: key, done: {
                        self.getNext(done: { nextPhoto, nextKey, nextNumber, nextDate in
                            self.startUploadingImageQueue(photo: nextPhoto, key: nextKey, teamNum: nextNumber, date: nextDate)
                        })
                    })
                } else {
                    self.photoManagerSleep(time: 60)
                    self.getNext(done: { (image, key, number, date) in
                        self.startUploadingImageQueue(photo: image, key: key, teamNum: number, date: date)
                    })
                }
            })
        }
    }
    
    /**
     This function stores the image onto Firebase Storage.
     */
    func storeOnFirebase(number: Int, date: String, image: UIImage, done: @escaping (_ didSucceed : Bool) ->()) {
        self.teamsFirebase.observeSingleEvent(of: .value, with: { (snap) -> Void in
            let name = self.makeFilenameForTeamNumAndIndex(number, date: date)
            var e: Bool = false
            self.firebaseStorageRef.child(name).putData(UIImagePNGRepresentation(image)!, metadata: nil) { [done] metadata, error in
                if (error != nil) {
                    print("LOOK! 0_0 no wifi")
                    print("ERROR: \(error.debugDescription)")
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL()?.absoluteString
                    self.putPhotoLinkToFirebase(downloadURL!, teamNumber: number)
                    e = true
                    print("UPLOADED: \(downloadURL!)")
                }
                done(e)
            }
        })
    }
    
    /**
     This function puts the URL link onto firebase, linking it to a randomnly generated string.
     */
    func putPhotoLinkToFirebase(_ link: String, teamNumber: Int) {
        let URLs = self.teamsFirebase.child("\(teamNumber)").child("pitAllImageURLs")
        self.writeArrayToFirebase(value: link, database: URLs)
    }
    
    /**
     This function removes the uploaded image key from the cache.
     */
    func removeFromCache(key: String, done: @escaping ()->()) {
        // Removes key from dataCache but leaves it in imageCache for image viewing
        teamsList.fetch(key: "teams").onSuccess({ (keysData) in
            var keysArray = NSKeyedUnarchiver.unarchiveObject(with: keysData) as! [String]
            for var i in 0 ..< keysArray.count {
                if String(keysArray[i]) != key {
                    i += 1
                } else {
                    keysArray.remove(at: i)
                    print("NOW WRITING TO CACHE: \(keysArray)")
                    let data = NSKeyedArchiver.archivedData(withRootObject: keysArray)
                    self.teamsList.set(value: data, key: "teams")
                    done()
                    break
                }
            }
        })
    }
    
    /**
     This function fetches an image key and its corresponding photo from the cache. If there are no photos, the function will wait one minute before calling itself again.
     */
    func getNext (done: @escaping (_ nextPhoto: UIImage, _ nextKey: String, _ nextNumber: Int, _ nextDate: String)->()) {
        self.teamsList.fetch(key: "teams").onSuccess({ (keysData) in
            self.backgroundQueue.async {
                // Choose key in index 0 of cache and find the corresponding image
                var teamNum : Int
                var date: String
                var nextPhoto = UIImage()
                var keysArray = NSKeyedUnarchiver.unarchiveObject(with: keysData) as! NSArray as! [String]
                if keysArray.count != 0 {
                    if keysArray.count > self.keyIndex {
                        print("KEYSARRAY: \(keysArray)")
                        let nextKey = String(keysArray[self.keyIndex])
                        let nextKeyArray = nextKey.components(separatedBy: "_")
                        teamNum = Int(nextKeyArray[0])!
                        date = nextKeyArray[1]
                        self.imageCache.fetch(key: nextKey).onSuccess({ (image) in
                            nextPhoto = image
                            done(nextPhoto, nextKey, teamNum, date)
                        }).onFailure({ Void in
                            self.backgroundQueue.async {
                                // Loops back through keysArray, removing any keys that do not fetch an image
                                self.removeArrayFromFirebase(dataToRemove: nextKey, teamNum: teamNum, keyToRemove: "pitImageKeys")
                                keysArray.remove(at: self.keyIndex)
                                self.keyIndex += 1
                                self.photoManagerSleep(time: 60)
                                self.getNext(done: { (image, key, number, date) in
                                    done(image, key, number, date)
                                })
                            }
                        })
                        // Gives time for the cache fetch to occur
                        self.photoManagerSleep(time: 1)
                        let keysData = NSKeyedArchiver.archivedData(withRootObject: keysArray)
                        self.teamsList.set(value: keysData, key: "teams")
                        self.keyIndex += 1
                    } else {
                        // keyIndex is out of the range of the keysArray, need to restart keyIndex at 0
                        //let keysData = NSKeyedArchiver.archivedData(withRootObject: keysArray)
                        //self.teamsList.set(value: keysData, key: "teams")
                        self.keyIndex = 0
                        self.getNext(done: { (image, key, number, date) in
                            done(image, key, number, date)
                        })
                    }
                } else {
                    // Nothing to be cached, retry in a minute
                    self.keyIndex = 0
                    self.photoManagerSleep(time: 60)
                    self.getNext(done: { (image, key, number, date) in
                        done(image, key, number, date)
                    })
                }
            }
        }).onFailure({ Void in
            self.backgroundQueue.async {
                self.photoManagerSleep(time: 60)
                self.getNext(done: { (image, key, number, date) in
                    done(image, key, number, date)
                })
            }
        })
    }
    
    /**
        This function removes an array value from firebase.
    */
    func removeArrayFromFirebase(dataToRemove: Any, teamNum: Int, keyToRemove: String) {
        teamsFirebase.child(String(teamNum)).observeSingleEvent(of: .value, with: { (snap) in
            var currentData = snap.childSnapshot(forPath: keyToRemove).value as! [String]
            for i in 0..<currentData.count{
                let value = currentData[i]
                if value == String(describing: dataToRemove) {
                    currentData.remove(at: i)
                    break
                }
            }
            self.teamsFirebase.child(String(teamNum)).child(keyToRemove).setValue(currentData)
        })
    }
    
    //MARK: Updating Cache
    
    /**
     This function adds the image key to the cache.
     */
    func addImageKey(key : String, number: Int) {
        // Adding to teamsList cache to upload photos
        teamsList.fetch(key: "teams").onSuccess({ (keysData) in
            var keysArray = NSKeyedUnarchiver.unarchiveObject(with: keysData) as! [String]
            keysArray.append(key)
            let data = NSKeyedArchiver.archivedData(withRootObject: keysArray)
            self.teamsList.set(value: data, key: "teams")
        }).onFailure({ Void in
            var keysArray: [String] = []
            keysArray.append(key)
            let data = NSKeyedArchiver.archivedData(withRootObject: keysArray)
            self.teamsList.set(value: data, key: "teams")
        })
        let imageKeys = teamsFirebase.child("\(number)").child("pitImageKeys")
        self.writeArrayToFirebase(value: key, database: imageKeys)
    }
    
    /**
     This function adds the image to the cache.
     */
    func addToFirebaseStorageQueue(image: UIImage, number: Int) {
        // Formatting date to be date in PST time (local time)
        let date = NSDate()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSS ZZZ"
        let localTimeZoneStr = formatter.string(from: date as Date)
        let key = "\(number)_\(localTimeZoneStr)"
        addImageKey(key: key, number: number)
        imageCache.set(value: image, key: key)
    }
    
    func writeArrayToFirebase(value: String, database: DatabaseReference) {
        database.observeSingleEvent(of: .value, with: { (snap) in
            var currentData = snap.value as? [String] ?? []
            currentData.append(value)
            database.setValue(currentData)
        })
    }
}


extension UIImage {
    public func imageRotatedByDegrees(_ degrees: CGFloat, flip: Bool) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        // calculate the size of the rotated view's containing box for our drawing spaaace
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        let t = CGAffineTransform(rotationAngle: degreesToRadians(degrees));
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        bitmap?.rotate(by: degreesToRadians(degrees));
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip) {
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        bitmap?.scaleBy(x: yFlip, y: -1.0)
        bitmap?.draw(cgImage!, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
