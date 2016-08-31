import UIKit

class RecordController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var studentIdField: UITextField!
    @IBOutlet var siteCodeField: UITextField!
    let imagePicker: UIImagePickerController! = UIImagePickerController()
    var imagePath: String = ""
    
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
    
    func getPathStart() -> String {
        let currentDate = NSDate()
        let myFormat = NSDateFormatter.dateFormatFromTemplate("ddMMMyyyy", options: 0, locale: NSLocale.currentLocale())
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = myFormat
        let convertedDate = dateFormatter.stringFromDate(currentDate)
        
        return self.studentIdField.text! + "-" + self.siteCodeField.text! + "-" + convertedDate + "-"
    }
    
    @IBAction func takeBeforePicture(sender: UIBarButtonItem) {
        self.imagePath = getPathStart() + "before.jpg"
        takePicture()
    }
    
    @IBAction func takeAfterPicture(sender: UIBarButtonItem) {
        self.imagePath = getPathStart() + "after.jpg"
        takePicture()
    }
    
    func cameraIsAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.Camera) && UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil
    }
    
    func takePicture() {
        if cameraIsAvailable() {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .Camera
            imagePicker.cameraCaptureMode = .Photo
            imagePicker.delegate = self
            presentViewController(imagePicker, animated: true, completion: {})
        }
    }
    
    func getDocumentsURL() -> NSURL {
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        
        return documentsURL
    }
    
    func fileInDocumentsDirectory(filename: String) -> String {
        let fileURL = getDocumentsURL().URLByAppendingPathComponent(filename)
        
        return fileURL.path!
    }
    
    func resetForNewImage() {
        self.studentIdField.text = ""
        self.imagePath = ""
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        let imageData = UIImageJPEGRepresentation(image, 0.6)
        
        do {
            try imageData!.writeToFile(fileInDocumentsDirectory(self.imagePath), options: .AtomicWrite)
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