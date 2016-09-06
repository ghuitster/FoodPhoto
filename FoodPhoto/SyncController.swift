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
        BOXContentClient.setClientID(Config.clientId, clientSecret: Config.clientSecret)
        
        BOXContentClient.defaultClient().authenticateWithCompletionBlock({(user: BOXUser!, error: NSError!) -> Void in
            if error == nil {
                print("Logged in user: \(user.login)")
            }
        })
    }
    
    @IBAction func syncImages(sender: AnyObject) {
        let documentsUrl =  NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        do {
            let directoryContents = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(documentsUrl, includingPropertiesForKeys: nil, options: [])
            print(directoryContents)
            
            let jpgFiles = directoryContents.filter{$0.pathExtension == "jpg"}
            print("jpg urls:", jpgFiles)
            let jpgFileNames = jpgFiles.flatMap({$0.URLByDeletingPathExtension?.lastPathComponent})
            print("jpg list:", jpgFileNames)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
}
