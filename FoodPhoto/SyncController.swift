import UIKit
import BoxContentSDK

class SyncController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func loginBox(sender: AnyObject) {
        BOXContentClient.defaultClient().authenticateWithCompletionBlock({(user: BOXUser!, error: NSError!) -> Void in
            if error == nil {
                self.syncImages()
            } else {
                self.displayAlert("Login Error", message: "There was a problem logging in")
            }
        })
    }
    
    func syncImages() {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        do {
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
            
            let jpgFiles = directoryContents.filter{$0.pathExtension == "jpg"}
            print("jpg urls:", jpgFiles)
            let jpgFileNames = jpgFiles.flatMap({$0.URLByDeletingPathExtension?.lastPathComponent})
            print("jpg list:", jpgFileNames)
            
        } catch {
            self.displayAlert("Sync Error", message: "There was a problem syncing")
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func logout(sender: AnyObject) {
        let logoutAlert = UIAlertController(title: "Logout", message: "Really log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        logoutAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {(action: UIAlertAction!) in
            BOXContentClient.defaultClient().logOut()
            self.displayAlert("Logout Success", message: "Successfully logged out")
        }))
        
        logoutAlert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: {(action: UIAlertAction!) in
        }))
        
        self.presentViewController(logoutAlert, animated: true, completion: nil)
    }
}
