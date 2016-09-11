import UIKit
import MessageUI

class AboutController: UIViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet var iconsLabel: UILabel!
    @IBOutlet var supportLabel: UILabel!
    
    override func viewDidLoad() {
        let iconsString = self.iconsLabel.text!
        let iconsMutableString = NSMutableAttributedString(string: iconsString, attributes: nil)
        iconsMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blueColor(), range: NSRange(location:51, length:19))
        self.iconsLabel.attributedText = iconsMutableString
        
        let supportString = self.supportLabel.text!
        let supportMutableString = NSMutableAttributedString(string: supportString, attributes: nil)
        supportMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blueColor(), range: NSRange(location:6, length:23))
        self.supportLabel.attributedText = supportMutableString
        
        let iconsTap = UITapGestureRecognizer(target: self, action: #selector(AboutController.openIconsLinkBrowser(_:)))
        self.iconsLabel.addGestureRecognizer(iconsTap)
        
        let supportTap = UITapGestureRecognizer(target: self, action: #selector(AboutController.openSupportEmail(_:)))
        self.supportLabel.addGestureRecognizer(supportTap)
        
        super.viewDidLoad()
    }
    
    func openIconsLinkBrowser(sender:UITapGestureRecognizer) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://icons8.com/")!)
    }
    
    func openSupportEmail(sender:UITapGestureRecognizer) {
        let mailComposeViewController = self.configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        
        mailComposerVC.setToRecipients(["usu.nutrition@gmail.com"])
        mailComposerVC.setSubject("FoodPhoto Support")
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let alertController = UIAlertController(title: "Could Not Send Email", message:
            "Your device could not send e-mail. Please check e-mail configuration and try again.", preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
