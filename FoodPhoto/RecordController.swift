import UIKit

class RecordController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var studentInformationField: UITextField!
    @IBOutlet var siteCodeField: UITextField!
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    var imagePath: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.studentInformationField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.studentInformationField {
            self.siteCodeField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return false
    }
    
    func getPathStart() -> String {
        let currentDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "ddMMMyyyy"
        let convertedDate = dateFormatter.stringFromDate(currentDate)
        
        let strippedStudentInformation = self.studentInformationField.text!.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        return strippedStudentInformation + "-" + self.siteCodeField.text! + "-" + convertedDate + "-"
    }
    
    @IBAction func takeBeforePicture(sender: UIBarButtonItem) {
        self.imagePath = self.getPathStart() + "before.jpg"
        self.takePicture()
    }
    
    @IBAction func takeAfterPicture(sender: UIBarButtonItem) {
        self.imagePath = self.getPathStart() + "after.jpg"
        self.takePicture()
    }
    
    func cameraIsAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.Camera) && UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil
    }
    
    func takePicture() {
        if self.fieldsContainInformation() {
            if self.cameraIsAvailable(){
                self.imagePicker.allowsEditing = false
                self.imagePicker.sourceType = .Camera
                self.imagePicker.cameraCaptureMode = .Photo
                self.imagePicker.delegate = self
                presentViewController(self.imagePicker, animated: true, completion: {})
            } else {
                self.displayAlert("Camera Not Available", message: "The Camera is not available")
            }
        } else {
            self.displayAlert("Empty Field(s)", message: "Make sure 'Student ID or Name' and 'Site Code' both contain information")
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func fieldsContainInformation() -> Bool {
        let strippedStudentInformation = self.studentInformationField.text!.stringByReplacingOccurrencesOfString(" ", withString: "")
        let strippedSiteCode = self.siteCodeField.text!.stringByReplacingOccurrencesOfString(" ", withString: "")
        
        let aFieldIsEmpty = (strippedStudentInformation == "") || (strippedSiteCode == "")
        
        return !aFieldIsEmpty
    }
    
    func getDocumentsURL() -> NSURL {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        
        return documentsURL
    }
    
    func fileInDocumentsDirectory(filename: String) -> String {
        let fileURL = self.getDocumentsURL().URLByAppendingPathComponent(filename)
        
        return fileURL.path!
    }
    
    func resetForNewImage() {
        self.studentInformationField.text = ""
        self.imagePath = ""
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        let imageData = UIImageJPEGRepresentation(image, 0.4)
        
        do {
            try imageData!.writeToFile(self.fileInDocumentsDirectory(self.imagePath), options: .AtomicWrite)
        } catch {
            print(error)
        }
        
        picker.dismissViewControllerAnimated(true, completion: {
            self.resetForNewImage()
        })
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: {
            self.resetForNewImage()
        })
    }
}
