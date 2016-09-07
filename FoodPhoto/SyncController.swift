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
    
    func syncImages() -> Void {
        var errorOccurred = false
        
        let rootFolderItemsRequest = BOXContentClient.defaultClient().folderItemsRequestWithID("0")
        rootFolderItemsRequest.performRequestWithCompletion({(items: [AnyObject]!, error: NSError!) -> Void in
            if error == nil {
                var foodPhotoFolderExists = false
                for item in items as! [BOXItem] {
                    if item.isFolder && item.name == "FoodPhoto" {
                        foodPhotoFolderExists = true
                        self.uploadImages(item.modelID)
                    }
                }
                
                if !foodPhotoFolderExists {
                    let foodPhotoFolderCreateRequest = BOXContentClient.defaultClient().folderCreateRequestWithName("FoodPhoto", parentFolderID: "0")
                    foodPhotoFolderCreateRequest.performRequestWithCompletion({(folder: BOXFolder!, error: NSError!) -> Void in
                        if error == nil {
                            self.uploadImages(folder.modelID)
                        } else {
                            errorOccurred = true
                            print(error)
                        }
                    })
                }
            } else {
                errorOccurred = true
                print(error)
            }
        })
        
        if errorOccurred {
            self.displayAlert("Sync Error", message: "There was a problem syncing")
        }
    }
    
    func uploadImages(foodPhotoFolderId: String) -> Void {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        do {
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: [])
            let jpgFiles = directoryContents.filter{$0.pathExtension == "jpg"}
            
            for imageUrl in jpgFiles {
                let imageName = imageUrl.lastPathComponent!
                
                self.uploadImage(foodPhotoFolderId, data: NSFileManager.defaultManager().contentsAtPath(imageUrl.path!)!, imageName: imageName)
            }
        } catch {
            
        }
    }
    
    func uploadImage(foodPhotoFolderId: String, data: NSData, imageName: String) -> Void {
        let uploadRequest = BOXContentClient.defaultClient().fileUploadRequestToFolderWithID(foodPhotoFolderId, fromData: data, fileName: imageName)
        uploadRequest.performRequestWithProgress({(totalBytesTransferred: Int64, totalBytesExpectedToTransfer: Int64) -> Void in
            // Update a progress bar, etc.
            }, completion: {(file: BOXFile!, error: NSError!) -> Void in
                if error == nil {
                    print("successfully uploaded " + imageName)
                } else {
                    print(error)
                }
        })
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
