import UIKit
import BoxContentSDK
import ReachabilitySwift

enum SyncError: ErrorType {
    case folderCreationError
}

class SyncController: UIViewController {
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var progressText: UILabel!
    var backgroundTask : UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    override func viewDidLoad() -> Void {
        super.viewDidLoad()
        
        self.updateProgress(0, total: 0)
    }

    override func didReceiveMemoryWarning() -> Void {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func beginSync(sender: AnyObject) -> Void {
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
                self.displayAlert("Login Error", message: "There was a problem logging in. The error was: " + error.box_localizedFailureReasonString(), error: error)
            }
        })
    }
    
    func syncImages() -> Void {
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
                            self.displayAlert("Sync Error", message: "There was a problem syncing. The error was: " + error.box_localizedFailureReasonString(), error: error)
                        }
                    })
                }
            } else {
                self.displayAlert("Sync Error", message: "There was a problem syncing. The error was: " + error.box_localizedFailureReasonString(), error: error)
            }
        })
    }
    
    func getJpgFilesInDocumentsDirectory() -> [NSURL] {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        var directoryContents: [NSURL]
        
        do {
            directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: [])
        } catch {
            self.displayAlert("Sync Error", message: "There was a problem syncing", error: error)
            return [NSURL]()
        }
        
        return directoryContents.filter{$0.pathExtension == "jpg"}
    }
    
    func uploadImages(foodPhotoFolderId: String) -> Void {
        let jpgFiles = self.getJpgFilesInDocumentsDirectory()
        
        let totalImages = jpgFiles.count
        var imagesUploaded = 0
        self.updateProgress(imagesUploaded, total: totalImages)

        let mySerialQueue = dispatch_queue_create("edu.usu.ndfs", DISPATCH_QUEUE_SERIAL)
        
        var imageFolderIds = [String: String]()
        
        do {
            imageFolderIds = try self.createImageFolderMapping(jpgFiles, foodPhotoFolderId: foodPhotoFolderId)
        } catch {
            return
        }
        
        for jpgFile in jpgFiles {
            dispatch_async(mySerialQueue) {
                self.backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
                    self.endBackgroundTask()
                })
                
                let semaphore = dispatch_semaphore_create(0)
                
                let imageName = jpgFile.lastPathComponent!
                let data = NSFileManager.defaultManager().contentsAtPath(jpgFile.path!)!
                let folderName = self.getFolderName(imageName)
                
                let uploadRequest = BOXContentClient.defaultClient().fileUploadRequestToFolderWithID(imageFolderIds[folderName], fromData: data, fileName: imageName)
                uploadRequest.performRequestWithProgress({(totalBytesTransferred: Int64, totalBytesExpectedToTransfer: Int64) -> Void in
                    }, completion: {(file: BOXFile!, error: NSError!) -> Void in
                        if error == nil {
                            do {
                                try NSFileManager.defaultManager().removeItemAtURL(jpgFile)
                            } catch {
                                dispatch_sync(dispatch_get_main_queue()) {
                                    self.displayAlert("Sync Error", message: "There was an error when uploading " + imageName, error: error)
                                }
                                return
                            }
                            
                            print("successfully uploaded " + imageName)
                            
                            imagesUploaded += 1
                            
                            
                            dispatch_sync(dispatch_get_main_queue()) {
                                self.updateProgress(imagesUploaded, total: totalImages)
                            }
                        } else {
                            dispatch_sync(dispatch_get_main_queue()) {
                                self.displayAlert("Sync Error", message: "There was an error when uploading " + imageName + ". The error was: " + error.box_localizedFailureReasonString(), error: error)
                            }
                        }
                        
                        self.endBackgroundTask()
                        dispatch_semaphore_signal(semaphore)
                })
                
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            }
        }
    }
    
    func createImageFolderMapping(jpgFiles: [NSURL], foodPhotoFolderId: String) throws -> [String: String] {
        var imageFolderIds = [String: String]()
        
        for jpgFile in jpgFiles {
            let imageName = jpgFile.lastPathComponent!
            let folderName = self.getFolderName(imageName)
            
            if(imageFolderIds[folderName] == nil) {
                let imageFolderId = self.getImageFolderId(folderName, foodPhotoFolderId: foodPhotoFolderId)
                
                if(imageFolderId == nil) {
                    throw SyncError.folderCreationError
                }
                
                imageFolderIds[folderName] = imageFolderId
            }
        }
        
        return imageFolderIds
    }
    
    func getFolderName(imageName: String) -> String {
        let imageNameArray = imageName.characters.split{$0 == "-"}.map(String.init)
        
        return imageNameArray[1] + "-" + imageNameArray[2]
    }
    
    func getImageFolderId(folderName: String, foodPhotoFolderId: String) -> String? {
        let mySerialQueue = dispatch_queue_create("edu.usu.ndfs.folderGetting", DISPATCH_QUEUE_SERIAL)
        var imageFolderId: String?
        
        let outerSemaphore = dispatch_semaphore_create(0)
        
        dispatch_async(mySerialQueue) {
            self.backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
                self.endBackgroundTask()
            })
            
            let semaphore = dispatch_semaphore_create(0)
            
            let foodPhotoItemsRequest = BOXContentClient.defaultClient().folderItemsRequestWithID(foodPhotoFolderId)
            foodPhotoItemsRequest.performRequestWithCompletion({(items: [AnyObject]!, error: NSError!) -> Void in
                if error == nil {
                    for item in items as! [BOXItem] {
                        if item.isFolder && item.name == folderName {
                            imageFolderId = item.modelID
                            break
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.displayAlert("Sync Error", message: "There was a problem syncing. The error was: " + error.box_localizedFailureReasonString(), error: error)
                    }
                }
                
                self.endBackgroundTask()
                dispatch_semaphore_signal(semaphore)
                dispatch_semaphore_signal(outerSemaphore)
            })
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
        
        dispatch_semaphore_wait(outerSemaphore, DISPATCH_TIME_FOREVER)
        
        if(imageFolderId == nil) {
            imageFolderId = self.createImageFolder(folderName, foodPhotoFolderId: foodPhotoFolderId)
        }
        
        return imageFolderId
    }
    
    func createImageFolder(folderName: String, foodPhotoFolderId: String) -> String? {
        var imageFolderId: String?
        let mySerialQueue = dispatch_queue_create("edu.usu.ndfs.folderCreation", DISPATCH_QUEUE_SERIAL)
        
        let outerSemaphore = dispatch_semaphore_create(0)
        
        dispatch_async(mySerialQueue) {
            self.backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler({
                self.endBackgroundTask()
            })
            
            let semaphore = dispatch_semaphore_create(0)
            
            let foodPhotoFolderCreateRequest = BOXContentClient.defaultClient().folderCreateRequestWithName(folderName, parentFolderID: foodPhotoFolderId)
            foodPhotoFolderCreateRequest.performRequestWithCompletion({(folder: BOXFolder!, error: NSError!) -> Void in
                if error == nil {
                    imageFolderId = folder.modelID
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.displayAlert("Sync Error", message: "There was a problem syncing. The error was: " + error.box_localizedFailureReasonString(), error: error)
                    }
                }
                self.endBackgroundTask()
                dispatch_semaphore_signal(semaphore)
                dispatch_semaphore_signal(outerSemaphore)
            })
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        }
        
        dispatch_semaphore_wait(outerSemaphore, DISPATCH_TIME_FOREVER)
        
        return imageFolderId
    }
    
    func endBackgroundTask() -> Void {
        UIApplication.sharedApplication().endBackgroundTask(self.backgroundTask)
        self.backgroundTask = UIBackgroundTaskInvalid
    }
    
    func updateProgress(imagesUploaded: Int, total: Int) -> Void {
        let progress = Float(imagesUploaded) / Float(total)
        self.progressText.text! = String(imagesUploaded) + " / " + String(total)
        
        self.progressBar.setProgress(progress, animated: true)
        
        if imagesUploaded == total && total != 0 {
            self.displayAlert("Sync Success", message: "All images successfully synced", error: nil)
        }
    }
    
    func displayAlert(title: String, message: String, error: ErrorType?) -> Void {
        print(error)
        let alertController = UIAlertController(title: title, message:
            message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func logout(sender: AnyObject) -> Void {
        let logoutAlert = UIAlertController(title: "Logout", message: "Are you really sure you want to log out of your Box account?", preferredStyle: UIAlertControllerStyle.Alert)
        
        logoutAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: {(action: UIAlertAction!) in
            BOXContentClient.defaultClient().logOut()
            self.displayAlert("Logout Success", message: "Successfully logged out", error: nil)
        }))
        
        logoutAlert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: {(action: UIAlertAction!) in
        }))
        
        self.presentViewController(logoutAlert, animated: true, completion: nil)
    }
}
