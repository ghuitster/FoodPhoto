import UIKit
import BoxContentSDK
import ReachabilitySwift

class SyncController: UIViewController {
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var progressText: UILabel!
    var backgroundTask : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.updateProgress(0, total: 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func beginSync(sender: AnyObject) {
        var reachability: Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            self.displayAlert("Internet Connection Error", message: "You don't have an Internet connection. Connect to the Internet and try again.", error: error)
            return
        }
        
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                self.loginBox()
            } else {
                let connectionAlert = UIAlertController(title: "Cellular Data Connection", message: "You're not connected to WiFi. Syncing may use lots of your data. Are you sure you want to continue?", preferredStyle: UIAlertControllerStyle.Alert)
                
                connectionAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (action: UIAlertAction!) in
                    self.loginBox()
                }))
                
                connectionAlert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: { (action: UIAlertAction!) in
                    return
                }))
                
                presentViewController(connectionAlert, animated: true, completion: nil)
            }
        } else {
            self.displayAlert("Internet Connection Error", message: "You don't have an Internet connection. Connect to the Internet and try again.", error: nil)
        }
    }
    
    func loginBox() -> Void {
        BOXContentClient.defaultClient().authenticateWithCompletionBlock({(user: BOXUser!, error: NSError!) -> Void in
            if error == nil {
                self.syncImages()
            } else {
                self.displayAlert("Login Error", message: "There was a problem logging in", error: error)
            }
        })
    }
    
    func syncImages() -> Void {
        var errorOccurred = false
        var theError: ErrorType? = nil
        
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
                            theError = error
                        }
                    })
                }
            } else {
                errorOccurred = true
                theError = error
            }
        })
        
        if errorOccurred {
            self.displayAlert("Sync Error", message: "There was a problem syncing", error: theError)
        }
    }
    
    func uploadImages(foodPhotoFolderId: String) -> Void {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        do {
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: [])
            let jpgFiles = directoryContents.filter{$0.pathExtension == "jpg"}
            
            let totalImages = jpgFiles.count
            var imagesUploaded = 0
            self.updateProgress(imagesUploaded, total: totalImages)
            
            var errored = false
            var theError: ErrorType? = nil
            let mySerialQueue = dispatch_queue_create("edu.usu.nutrition", DISPATCH_QUEUE_SERIAL)
            
            for jpgFile in jpgFiles {
                dispatch_async(mySerialQueue) {
                    self.backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
                        self.endBackgroundTask()
                    })
                    
                    let semaphore = dispatch_semaphore_create(0)
                    
                    let imageName = jpgFile.lastPathComponent!
                    let data = NSFileManager.defaultManager().contentsAtPath(jpgFile.path!)!
                    let uploadRequest = BOXContentClient.defaultClient().fileUploadRequestToFolderWithID(foodPhotoFolderId, fromData: data, fileName: imageName)
                    
                    uploadRequest.performRequestWithProgress({(totalBytesTransferred: Int64, totalBytesExpectedToTransfer: Int64) -> Void in
                        }, completion: {(file: BOXFile!, error: NSError!) -> Void in
                            if error == nil {
                                do {
                                    try NSFileManager.defaultManager().removeItemAtURL(jpgFile)
                                } catch {
                                    errored = true
                                    theError = error
                                }
                                
                                print("successfully uploaded " + imageName)
                                
                                imagesUploaded += 1
                                
                                dispatch_sync(dispatch_get_main_queue()) {
                                    self.updateProgress(imagesUploaded, total: totalImages)
                                }
                            } else {
                                theError = error
                                errored = true
                            }
                            
                            self.endBackgroundTask()
                            dispatch_semaphore_signal(semaphore)
                    })
                    
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
                }
            
                if errored {
                    break
                }
            }
            
            if errored {
                self.displayAlert("Sync Error", message: "There was an error when syncing", error: theError)
            }
        } catch {
            self.displayAlert("Sync Error", message: "There was a problem syncing", error: error)
        }
    }
    
    func endBackgroundTask() -> Void {
        UIApplication.sharedApplication().endBackgroundTask(self.backgroundTask)
        self.backgroundTask = UIBackgroundTaskInvalid
    }
    
    func updateProgress(imagesUploaded: Int, total: Int) -> Void {
        let progress = Float(imagesUploaded) / Float(total)
        self.progressText.text! = String(imagesUploaded) + " / " + String(total)
        
        self.progressBar.setProgress(progress, animated: true)
        
        if imagesUploaded == total {
            self.displayAlert("Sync Success", message: "All images successfully synced", error: nil)
        }
    }
    
    func displayAlert(title: String, message: String, error: ErrorType?) {
        print(error)
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func logout(sender: AnyObject) {
        let logoutAlert = UIAlertController(title: "Logout", message: "Really log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        logoutAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {(action: UIAlertAction!) in
            BOXContentClient.defaultClient().logOut()
            self.displayAlert("Logout Success", message: "Successfully logged out", error: nil)
        }))
        
        logoutAlert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: {(action: UIAlertAction!) in
        }))
        
        self.presentViewController(logoutAlert, animated: true, completion: nil)
    }
}
