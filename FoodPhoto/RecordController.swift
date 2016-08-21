//
//  StudentInformationController.swift
//  FoodPhoto
//
//  Created by David Barley on 8/16/16.
//  Copyright © 2016 Utah State University. All rights reserved.
//

import UIKit

class RecordController: UIViewController, UITextFieldDelegate {
    @IBOutlet var studentIdField: UITextField!
    @IBOutlet var siteCodeField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.studentIdField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == studentIdField {
            self.siteCodeField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return false
    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        let studentId = self.studentIdField.text
//        let siteCode = self.siteCodeField.text
//        
//        let destinationViewController = segue.destinationViewController as! BeforeAfterController
//        destinationViewController.studentId = studentId
//        destinationViewController.siteCode = siteCode
//        
//        self.studentIdField.text = ""
//    }

}

