import UIKit

class SyncController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
