
//
//  PSUIElement.swift
//  DropboxPhotoTest
//
//  Created by Bryton Moeller on 5/12/16.
//  Copyright © 2016 citruscircuits. All rights reserved.
//

import Foundation
import Firebase

/// PSUI (Pit Scout User Interface) elements will subclass from this. These Elements will handle the updating of their content on firebase when the user changes the UI, they will also handle keeping themselves up to date with changes on Firebase.
class PSUIFirebaseViewController : UIViewController {
    let red = UIColor(red: 243/255, green: 32/255, blue: 5/255, alpha: 1)
    var initialValue : Any?
    var titleText = ""
    var neededType : NeededType? {
        didSet {
            firebaseRef?.observeSingleEvent(of: .value, with: { (snap) -> Void in
                self.set(snap.value!)
            })
        }
    }
    var previousValue : Any? = ""
    var hasOverriddenUIResponse = false
    var UIResponse : ((Any)->())? = {_ in } {
        didSet {
            self.connectWithFirebase()
            hasOverriddenUIResponse = true
        }
    }
    var firebaseRef : DatabaseReference?
    
    func setup(_ titleText : String, firebaseRef : DatabaseReference, initialValue : Any?) {
        self.titleText = titleText
        self.initialValue = initialValue
        self.firebaseRef = firebaseRef
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.translatesAutoresizingMaskIntoConstraints = true
    }
    
    enum NeededType {
        case int
        case float
        case bool
        case string
    }
    
    func set(_ value: Any) {
        if neededType != nil {
            if neededType == .int {
                if Int(String(describing: value)) == nil {
                    self.view.backgroundColor = red
                } else {
                    self.view.backgroundColor = UIColor.white
                    self.firebaseRef?.setValue(Int(String(describing: value)))
                    UIResponse!(value)
                }
            } else if neededType == .float {
                if Float(String(describing: value)) == nil {
                    self.view.backgroundColor = red
                } else {
                    self.view.backgroundColor = UIColor.white
                    self.firebaseRef?.setValue(Float(String(describing: value)))
                    UIResponse!(value)
                }
            } else if neededType == .string {
                if value as? String == nil {
                    self.view.backgroundColor = red
                } else {
                    self.view.backgroundColor = UIColor.white
                    self.firebaseRef?.setValue(String(describing: value))
                    UIResponse!(value)
                }
            } else if neededType == .bool {
                if value as? Bool == nil {
                    self.view.backgroundColor = red
                } else {
                    self.view.backgroundColor = UIColor.white
                    self.firebaseRef?.setValue(value as! Bool)
                    UIResponse!(value)
                }
            }
        } else {
            self.firebaseRef?.setValue(value)
            UIResponse!(value)
        }
    }
    
    func connectWithFirebase() {
        self.firebaseRef!.observe(DataEventType.value) { (snapshot : DataSnapshot) -> Void in
            if String(describing: snapshot.value) != String(describing: self.previousValue) {
                self.set(snapshot.value! as Any)
            }
            self.previousValue = snapshot.value as Any?
        }
    }
    
    func setDoneOnKeyboard(textField: UITextField) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(PSUIFirebaseViewController.dismissKeyboard))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        textField.inputAccessoryView = keyboardToolbar
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

/// Just a few customizations of the text input view for the pit scout. See the `PSUIFirebaseViewController`.
class PSUITextInputViewController : PSUIFirebaseViewController, UITextFieldDelegate {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField : UITextField!
    
    override func viewDidLoad() {
        let currentResponse = self.UIResponse
        super.setDoneOnKeyboard(textField: textField)
        if !hasOverriddenUIResponse {
            self.UIResponse = { value in
                currentResponse!(value)
                self.textField.text = value as? String ?? (value as? NSNumber)?.stringValue ?? ""
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textField.delegate = self
        self.label.text = super.titleText
        if String(describing: textField.text) == "" {
            if String(describing: super.initialValue) != "" && String(describing: super.initialValue) != "nil" {
                self.textField.text = super.initialValue as? String ?? (super.initialValue as? NSNumber)?.stringValue ?? ""
            }
    
        }
        if neededType == .int {
            textField.keyboardType = UIKeyboardType.decimalPad
        }
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        initialValue = sender.text
        super.set(sender.text!)
    }
}

class PSUISwitchViewController : PSUIFirebaseViewController {
    @IBOutlet weak var toggleSwitch: UISwitch!
    @IBOutlet weak var label: UILabel!
    
    @IBAction func switchSwitched(_ sender: UISwitch) {
        super.set(sender.isOn as AnyObject)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.neededType = .bool
        self.toggleSwitch.setOn(super.initialValue as? Bool ?? false, animated: true)
        super.UIResponse = { value in
            self.toggleSwitch.setOn(value as! Bool, animated: true)
        }
        self.label.text = super.titleText
        
    }
}

class PSUISegmentedViewController : PSUIFirebaseViewController {
    @IBOutlet weak var segmentedController: UISegmentedControl!
    @IBOutlet weak var label: UILabel!
    var segments : [String] = []
    var selectedIndex : Int?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //self.segmentedController.numberOfSegments = segments.count
        segmentedController.removeAllSegments()
        for i in 0..<segments.count {
            self.segmentedController.insertSegment(withTitle: segments[i], at: i, animated: true)
        }
        
        if String(describing:initialValue) != "Optional(<null>)" {
            print(initialValue)
            selectedIndex = segments.index(of: String(describing: initialValue as? Int))
        }
        if selectedIndex != nil {
            segmentedController.selectedSegmentIndex = selectedIndex!
        }
        
        /* self.neededType = .int
         self.segmentedController.selectedSegmentIndex = super.initialValue as? Int ?? 0
         super.UIResponse = { value in
         self.segmentedController.selectedSegmentIndex = value as! Int
         } */
        self.label.text = super.titleText
        
        
    }
    
    @IBAction func selectedSegmentChanged(_ sender: UISegmentedControl) {
        let index = segmentedController.selectedSegmentIndex
        initialValue = segments[index] as String
        super.set(segments[index] as String)
    }
}

class PSUIButton : UIButton {
    let white = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
    let green = UIColor(red: 119/255, green: 218/255, blue: 72/255, alpha: 1.0)
    var press : (_ sender : UIButton)->() = {_ in } //This is an empty function of the type (sender : UIButton)->().
    convenience init(title : String, width : Int, y: Int, buttonPressed : @escaping (_ sender : UIButton)->()) {
        // Starts 80 from the left side to give a button buffer
        self.init(frame: CGRect(x: 80, y: y, width: width, height: 45))
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor =  UIColor.white.cgColor
        layer.backgroundColor = UIColor.lightGray.cgColor
        self.press = buttonPressed
        self.titleLabel?.font = UIFont.systemFont(ofSize: 32)
        self.setTitle(title, for: UIControlState())
        self.setTitleColor(white, for: UIControlState())
        self.isUserInteractionEnabled = true
        let tapAddImageButton = UITapGestureRecognizer(target: self, action: #selector(PSUIButton.buttonPressed(_:)))
        self.addGestureRecognizer(tapAddImageButton)
    }
    
    func redrawWithWidth(_ w: CGFloat) {
        self.frame.size.width = w
        self.setNeedsLayout()
    }
    
    @objc func buttonPressed(_ button : UIButton) {
        // layer.backgroundColor = UIColor.green.cgColor
        self.press(button)
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
