//
//  joinAClassScreen.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 3/15/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class joinAClass:UIViewController
{
    let ref = Database.database().reference()
    let ClassRef = Database.database().reference(withPath: "Classes")
    var ActualClass = Database.database().reference(withPath: "nil")
    let UsersToReference = Database.database().reference(withPath: "AllUsers")
    var numberOfDays:Int = 0
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var UsersInfo: [String: Int] = [:]
    
    override func viewDidLoad() {
        let buttonClickPath = Bundle.main.path(forResource: "buttonClick.mp3", ofType: nil)!
        let buttonClickSound = NSURL(fileURLWithPath: buttonClickPath)
        do {
            try buttonSoundPlayer = AVAudioPlayer(contentsOf: buttonClickSound as URL)
            buttonSoundPlayer.prepareToPlay()
        } catch {
            print("Bummer....")
        }
        let backTickPath = Bundle.main.path(forResource: "backTick.mp3", ofType: nil)!
        let backTickSound = NSURL(fileURLWithPath: backTickPath)
        do {
            try backTickSoundPlayer = AVAudioPlayer(contentsOf: backTickSound as URL)
            backTickSoundPlayer.prepareToPlay()
        } catch {
        }
        errorMessageLabel.isHidden = true
    }

    @IBAction func joinDidTouch(_ sender: Any) {
        buttonSoundPlayer.play()
        let enteredString = enterClassCodeText.text
        if enteredString?.count == 8
        {
            self.ActualClass = Database.database().reference(withPath: enteredString!)
            ClassRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(enteredString!)
            {
                print("Found that....")
                self.ActualClass.child("Information").child("NumberOfDays").observeSingleEvent(of: .value, with: { (snapshotT) in
                    //A class will have the numberOfDays child if it hasn't been activated.
                    if snapshot.exists()
                    {
                        print("Found that")
                        self.numberOfDays = snapshotT.value as! Int
                        //change username if needed.
                        if self.newUsernameField.text != ""
                        {
                            let cleanedField = self.removeSpecialCharsFromString(text: self.newUsernameField.text!)
                            let alert = UIAlertController(title: "Joining Class", message: "Your new username will be: \(cleanedField) is that okay?",    preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
                                let Users = Database.database().reference(withPath: "AllUsers")
                                Users.child(UsersInformation.currentUsersUID).child("Username").setValue(cleanedField)
                                UsersInformation.currentUsersUsername = cleanedField
                                self.checkIfAlreadyInThisClass(enteredString: enteredString!)
                            }))
                            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction) in
                                alert.dismiss(animated: true, completion: nil)
                            }) )
                            self.present(alert, animated: true, completion: nil)
                            
                        }
                        else{
                            self.checkIfAlreadyInThisClass(enteredString: enteredString!)
                        }
                        // ------ end changing class ----
                    }
                    else
                    {
                        self.errorMessageLabel.isHidden = false
                        self.errorMessageLabel.text = "This class is already active, and you can no longer join."
                    }
                    
                })
                
            }
            else
            {
                //class doesn't exist.
                self.errorMessageLabel.isHidden = false
                self.errorMessageLabel.text = "This class does not exist."
            }
            })
        }
        else
        {
            self.errorMessageLabel.isHidden = false
            self.errorMessageLabel.text = "Not enough characters, all codes are 8 characters long."
        }
        
    }
    func removeSpecialCharsFromString(text: String) -> String
    {
        let okayChars : Set<Character> =
            Set(".#$[]")
        return String(text.filter {!okayChars.contains($0) })
    }
    func checkIfAlreadyInThisClass(enteredString:String)
    {
        self.ActualClass.child("AllUserNames").child(UsersInformation.currentUsersUsername).observeSingleEvent(of: .value, with: { (snapshoty) in
            if snapshoty.exists()
            {
                self.errorMessageLabel.isHidden = false
                self.errorMessageLabel.text = "Your username has been taken in this class"
            }
            else{
                print("Actually Joining")
                self.actuallyjoinClass(enteredString: enteredString)
            }
        })
    }
    func actuallyjoinClass(enteredString:String)
    {
        //joining class
        //we already observed the information child once, it seems like we shouldn't do it twice. consider fixing it.
        ref.child(enteredString).child("Information").observeSingleEvent(of: .value) { (snapshot) in
            let information = snapshot.value as! [String:Any]
            if snapshot.exists()
            {
                print("Got that one!")
                UsersInformation.multiplier = information["Multiplier"] as! Float
                let settings = information["Settings"] as! [String:Bool]
                
                // if CountryInequality is true, then select random amount of resources, else select 3
                self.chooseResource(numberOfResources: (settings["CountryInequality"]! == true ? Int(arc4random() % 4) + 1 : 3), fixedResources: settings["FixedResources"]!, multiplier: UsersInformation.multiplier)
                
               if(settings["FixedResources"] == false)
               {
                self.ActualClass.child("UsersMultipliers").child(UsersInformation.currentUsersUsername).setValue(UsersInformation.individualResourceMultiplier)
                    print("UsersMultipliers being set as : \(UsersInformation.individualResourceMultiplier)")
                }
                UsersInformation.currentUsersResources = self.UsersInfo
                self.UsersInfo["Wealth"] = 0
                //adding User's resources to that class.
                self.ActualClass.child("NamesOfUsers").child("\(UsersInformation.currentUsersUsername)").setValue(self.UsersInfo)
                //set username to usernamelist.
                self.ActualClass.child("AllUserNames").child(UsersInformation.currentUsersUsername).setValue("Active")
                // Save this class code for this user's profile
                self.UsersToReference.child("\(UsersInformation.currentUsersUID)").child("ActiveClass").setValue(enteredString)
                UsersInformation.classWeAreIn = enteredString
                UsersInformation.weAreInClass = true
                print(self.UsersInfo)
                print(UsersInformation.currentUsersActiveResources)
                print(UsersInformation.currentUsersResources)
                self.performSegue(withIdentifier: "backToOverview", sender: nil)
            }
        }
    }
    func chooseResource(numberOfResources:Int, fixedResources:Bool, multiplier:Float)
    {
        //I'm assuming that the UsersInformation.currentUsersResources are nil at this point
        //This function should pick the resources based on the level system. Needs checking
        let arrays:[String:[String]] = ["Set1": ["Wheat", "Sugar", "Spices"], "Set2": ["Brick", "Lumber", "Stone", "Rope", "Wool"], "Set3": ["Iron", "Oil", "Glass", "Rubber"]]
        var avaliableSets:[String] = ["Set1", "Set2", "Set3"]
        for _ in 1...numberOfResources // make sure this goes the number of times it is supposed to
        {
            let nextResource:String = pickResourceFromArray(array: arrays[selectSet(avaliableSets: &avaliableSets)]!)
            
            if (fixedResources == false)
            {
                UsersInformation.currentUsersActiveResources.append(nextResource)
                UsersInformation.individualResourceMultiplier[nextResource] = multiplier
                UsersInformation.currentUsersResources["\(nextResource)X"] = 0
                self.UsersInfo["\(nextResource)X"] = 0
            }
            else {
                //calculate the total possible number of resources avaliable for fixed resources.
                UsersInformation.currentUsersResources[nextResource] = Int(Float(86400 * numberOfDays) * multiplier)
                self.UsersInfo[nextResource] = Int(Float(86400 * numberOfDays) * multiplier)
            }
        }
    }
    func selectSet(avaliableSets:inout [String]) -> String
    {
        //this function selects which set to take a resource from. Once a resource has been taken from a set, that set is removed. Because of this the user will get a resource from each set. With the exception of if the user is going to get 4 resources, then they will get two resources from Set3. Because we know where the resources are coming from there is no chance that the user will have enough resources to build right away.
        if (avaliableSets.count == 0) // this would mean that the user has 4 resources, so let them select their 4th resources from Set3
        {
            return "Set3"
        }
        else {
            let setNumber:Int = Int(arc4random()) % avaliableSets.count
            let set:String = avaliableSets[setNumber]
            avaliableSets.remove(at: setNumber)
            return set
        }
    }
    func pickResourceFromArray(array:[String]) -> String
    {
        let resourceNumber = Int(arc4random()) % array.count
        return array[resourceNumber]
    }
    @IBAction func backButtonDidTouch(_ sender: Any) {
        backTickSoundPlayer.play()
        performSegue(withIdentifier: "backToOverview", sender: nil)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    
    
    @IBOutlet var newUsernameField: UITextField!
    @IBOutlet var enterClassCodeText: UITextField!
    @IBOutlet var errorMessageLabel: UILabel!
}
