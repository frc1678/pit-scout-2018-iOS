//
//  MissingDataViewController.swift
//  DropboxPhotoTest
//
//  Created by Bryton Moeller on 3/17/16.
//  Copyright © 2016 citruscircuits. All rights reserved.
//

import UIKit
import Firebase

class MissingDataViewController : UIViewController {
    @IBOutlet weak var mdTextView: UITextView!
    /// Teams Firebase Snapshot
    var snap : DataSnapshot? = nil{
        didSet {
            self.viewDidLoad()
        }
    }
    
    let firebaseKeys = ["pitProgrammingLanguage", "pitAvailableWeight", "pitDriveTrain", "pitDidDemonstrateCheesecakePotential", "pitMaxHeight", "pitClimberType"]
    
    let ignoreKeys = ["pitImageKeys", "pitAllImageURLs"]
    
    override func viewWillAppear(_ animated: Bool) {
        mdTextView.bounds.size.height = mdTextView.contentSize.height + 100
        self.preferredContentSize.height = mdTextView.bounds.size.height
    }
    
    override func viewDidLoad() {
        if let snap = self.snap {
            for team in snap.children.allObjects {
                let t = (team as! DataSnapshot).value as! [String: AnyObject]
                if t["number"] != nil {
                    if t["pitSelectedImageName"] == nil {
                        self.updateWithText("\nTeam \(t["number"]!) has no selected image name.", color: UIColor.blue)
                    }
                    var dataNils : [String] = []
                    for key in self.firebaseKeys {
                        if t[key] == nil && !self.ignoreKeys.contains(key) {
                            dataNils.append(key)
                        }
                    }
                    for dataNil in dataNils {
                        self.updateWithText("\nTeam \(t["number"]!) is missing datapoint: \(dataNil).", color: UIColor.orange)
                    }
                }
            }
        }
    }
    
    func updateWithText(_ text : String, color: UIColor) {
        let currentText : NSMutableAttributedString = NSMutableAttributedString(attributedString: self.mdTextView.attributedText)
        currentText.append(NSMutableAttributedString(string: text, attributes: [NSForegroundColorAttributeName: color]))
        self.mdTextView.attributedText = currentText
        mdTextView.bounds.size.height = mdTextView.contentSize.height + 100
        self.preferredContentSize.height = mdTextView.bounds.size.height
    }
    
    
    func adaptivePresentationStyleForPresentationController(
        _ controller: UIPresentationController!) -> UIModalPresentationStyle {
            return .none
    }
    
    // used to show loading of missing data, come back to later
    func showActivityIndicatory(uiView: UIView) {
        let actInd: UIActivityIndicatorView = UIActivityIndicatorView()
        actInd.frame = CGRect(x: 0.0, y: 0.0, width: 0.0, height: 40.0);
        actInd.center = uiView.center
        actInd.hidesWhenStopped = true
        actInd.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.whiteLarge
        uiView.addSubview(actInd)
        actInd.startAnimating()
    }
}
