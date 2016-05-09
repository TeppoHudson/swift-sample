//
//  FrontTableViewController.swift
//  Photographers
//
//  Created by Teppo Hudson on 16/02/16.
//  Copyright © 2016 Fibo. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import AssetsLibrary

class FrontTableViewController: UITableViewController, AddRollDelegate, RollInfoDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let SegueIdentifier = "ShowRollinfoSegue"
    let AddRollIdentifier = "AddRollSegue"

//    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    var bgImagesArray = [String](arrayLiteral: "camera_old.jpg","camera_old2.jpg","camera_old3.jpg")
    var selectedIndex: Int!
    
    // Core Data model
    var rolls = [NSManagedObject]()
    // sample Model
    var activeRollArray: [RollObject] = rollData
    
    var imagePicker: UIImagePickerController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.title = "RETAKE"
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0)
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        imagePicker.allowsEditing = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest(entityName: "Roll")

        do {
            let fetchedResult = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            if let results = fetchedResult
            {
                rolls = results
            }
            else
            {
                print("Could not fetch result")
            }

        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if (section == 1) {return fullRollArray.count}
        return rolls.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch(section)
        {
        case 0:return "My Rolls"
        case 1:return "Full Rolls"
        default :return ""
        }
    }
        
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> FrontTableCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FrontTableCell", forIndexPath: indexPath) as! FrontTableCell
        let roll = rolls[indexPath.row]

        if indexPath.section == 0 {
            
            cell.nameLabel?.text = roll.valueForKey("name") as? String
            let current = roll.valueForKey("currentCount") as! NSNumber
            let total = roll.valueForKey("totalCount") as! NSNumber
                
            cell.rollcounter?.text = String(current)+"/"+String(total)
            
            
            cell.addPicture.hidden = false
            if current == total {
                cell.rollcounter?.text = "Full"
                cell.addPicture.hidden = true
            }
        }

        cell.cellImage.image = UIImage(named:bgImagesArray[random() % 3])!
        
        cell.infoButton.tag = indexPath.row
        cell.addPicture.tag = indexPath.row
        cell.addPicture.hasShadow = true
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let button = UIButton()
        button.tag = indexPath.row
        self.performSegueWithIdentifier(SegueIdentifier, sender: button)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath
        indexPath: NSIndexPath)
    {
        if editingStyle == .Delete
        {
            self.deleteName(indexPath.row)
        }
    }

    
    // MARK: - Navigation
    @IBAction func largeButtonclicked(button:UIButton){
        openCamera(button.tag)
    }
    
    @IBAction func infoclicked(button:UIButton){
        self.performSegueWithIdentifier(SegueIdentifier, sender: button)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueIdentifier {
            let destinationVC = segue.destinationViewController as! RTRollInfoViewController
            if let button = sender as? UIButton {
                destinationVC.delegate = self
                destinationVC.selectedRoll = rolls[button.tag]
                destinationVC.selectedIndex = button.tag
                
            }
        }
        if segue.identifier == AddRollIdentifier {
            let nav = segue.destinationViewController as! UINavigationController
            let destinationVC = nav.topViewController as! RTaddRollViewController
            destinationVC.delegate=self;
        }
    }
    
    // AddRoll Delegate callback
    func savePurchasedRoll(Roll : RollObject) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let entity =  NSEntityDescription.entityForName("Roll",
                                                        inManagedObjectContext:managedContext)
        
        let newroll = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        newroll.setValue(Roll.name, forKey: "name")
        newroll.setValue(NSNumber(longLong: Roll.rollCurrentCount), forKey: "currentCount")
        newroll.setValue(NSNumber(longLong: Roll.rollTotalCount), forKey: "totalCount")
        newroll.setValue(Roll.full, forKey: "full")
        
        do {
            try managedContext.save()
            rolls.append(newroll)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        activeRollArray.insert(Roll, atIndex: 0)
        self.tableView.reloadData()
    }
    
    
    //RollInfo Delegate callback
    func receivedUpdatedRollInfo(rollName : String, atIndex: Int){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Roll")
        
        do {
            let fetchResult = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            
            if let theResult = fetchResult {
                let rollToUpdate = theResult[atIndex] as NSManagedObject
                rollToUpdate.setValue(rollName, forKey:"name")
                
                do
                {
                    try managedContext.save()
                }
                catch
                {
                    print("There is some error.")
                }
                
                if rolls .contains(rollToUpdate)
                {
                    rolls.replaceRange(atIndex...atIndex, with: [rollToUpdate])
                    self.tableView.reloadData()
                }
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        tableView.reloadData()
    }

    
    
    // Mark: - Unwind Segues
    @IBAction func cancelToActiveRollsViewController(segue:UIStoryboardSegue) {
    }

    // Mark: - Camera Delegate Methods
    
    func openCamera(index:Int){
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.Camera) {
                print(index)
                self.selectedIndex = index
                self.presentViewController(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Error", message: "Your device has no camera", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { action in
                switch action.style{
                case .Default:
                    return
                case .Cancel:
                    return
                case .Destructive:
                    return
                }
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }

    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        let thisroll = rolls[self.selectedIndex]
        let currentCount = thisroll.valueForKey("currentCount") as? NSNumber
        let newcount = currentCount!.longLongValue + 1
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Roll")
//        fetchRequest.predicate = NSPredicate(format: "objectID = %@", thisroll.objectID)
        
        do {
            let fetchResult = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            
            if let theResult = fetchResult {
                let rollToUpdate = theResult[self.selectedIndex] as NSManagedObject
                rollToUpdate.setValue(NSNumber(longLong: newcount), forKey:"currentCount")
                
                do
                {
                    try managedContext.save()
                }
                catch
                {
                    print("There is some error.")
                }
                
                if rolls .contains(rollToUpdate)
                {
                    rolls.replaceRange(self.selectedIndex...self.selectedIndex, with: [rollToUpdate])
                    self.tableView.reloadData()
                }
            }

        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        //        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
    }
    
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // Not in the final production version
    func deleteName(atIndex : Int)
    {
        let appDelegate    = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let objectToRemove = rolls[atIndex] as NSManagedObject
        
        managedContext.deleteObject(objectToRemove)
        
        do
        {
            try managedContext.save()
        }
        catch
        {
            print("There is some error while updating CoreData.")
        }
        
        rolls.removeAtIndex(atIndex)
        
        self.tableView.reloadData()
    }
    

}
