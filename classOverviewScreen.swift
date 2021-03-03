//
//  ViewController.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 2/27/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//
//We could store class codes by Teachers Username, because Usernames are always unique

import UIKit
import Firebase
import AVFoundation

extension UIApplication
{
    class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController?
    {
        if let nav = base as? UINavigationController
        {
            let top = topViewController(nav.visibleViewController)
            return top
        }
        
        if let tab = base as? UITabBarController
        {
            if let selected = tab.selectedViewController
            {
                let top = topViewController(selected)
                return top
            }
        }
        
        if let presented = base?.presentedViewController
        {
            let top = topViewController(presented)
            return top
        }
        return base
    }
}

class classOverviewScreen: UIViewController {
    
    let UsersToReference = Database.database().reference(withPath: "AllUsers")
    var classReference = Database.database().reference(withPath: "nil")
    var numberOfButtons = 0
    var startingPoint = 0
    var sliderIsUp:Bool = false
    var callLayoutOnlyOnce:Bool = true
    var leaderboard:Bool = true
    var UpdateLabelTimer:Timer = Timer()
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var slideSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLayoutSubviews() {
        if callLayoutOnlyOnce
        {
            callLayoutOnlyOnce = false
            let distanceBetweenButtons = BuildButton.frame.midY - TradeButton.frame.midY
            ResourcesButton.frame = CGRect(x: 0, y: 0, width: 161, height: 68)
            //let spaceBetweenButtons = distanceBetweenButtons/2 - 29
            ResourcesButton.center = CGPoint(x: self.view.frame.midX, y: (TradeButton.frame.midY + (distanceBetweenButtons/2)))
            //ResourcesButton.topAnchor.constraint(equalTo: TradeButton.frame.maxY + spaceBetweenButtons)
            //ResourcesButton.centerXAnchor.constraint(equalTo: )
            ResourcesLabel.frame = CGRect(x: 0, y: 0, width: ResourcesButton.frame.width, height: 21)
            ResourcesLabel.center = CGPoint(x: ResourcesButton.frame.midX, y: ResourcesButton.frame.midY - 5)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        UpdateLabelTimer.invalidate()
        Database.database().reference(withPath: UsersInformation.classWeAreIn).child("Information").removeAllObservers()
    }
    override func viewDidLoad()
    {
        /*
         Every time we enter this page we want these things to happen
         ******************* Start every time things ******************
         */
        super.viewDidLoad()
        let buttonClickPath = Bundle.main.path(forResource: "buttonClick.mp3", ofType: nil)!
        let buttonClickSound = NSURL(fileURLWithPath: buttonClickPath)
        let slidePath = Bundle.main.path(forResource: "slide.mp3", ofType: nil)!
        let slideSound = NSURL(fileURLWithPath: slidePath)
        do {
            try buttonSoundPlayer = AVAudioPlayer(contentsOf: buttonClickSound as URL)
            buttonSoundPlayer.enableRate = true
            buttonSoundPlayer.prepareToPlay()
        } catch {
            print("Bummer....")
        }
        do {
            try slideSoundPlayer = AVAudioPlayer(contentsOf: slideSound as URL)
            slideSoundPlayer.prepareToPlay()
        } catch {
            print("to bad...")
        }
        /*
         ******************* End every time things ******************
         ******************* Begin Only second time on things **********************
        */
        if UsersInformation.firstTimeAround == false
        {
            manipulateOutlets(notInClass: !UsersInformation.weAreInClass)
            if UsersInformation.classIsActive
            {
                ActivateLabel.text = "Time Remaining: ...."
                //when we immediately called updateTimeRemaining it didn't work because the view hadn't finished laying out yet, so we wait 1 second then call it.
                _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(classOverviewScreen.updateTimeRemaining), userInfo: nil, repeats: false)
                UpdateLabelTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.updateTimeRemaining), userInfo: nil, repeats: true)
            }
            if (UsersInformation.weAreInClass)
            {
                observeEndDate()
            }
        }
        /*
         ***************** End only second time on things ******************
         ***************** Begin only first time things ******************
         */
        if UsersInformation.firstTimeAround
        {
            determineEmailUsernameAndClass()
            UsersInformation.firstTimeAround = false
        }
        // *************** End only first time things **************
        if UsersInformation.weAreInClass
        {
            wealthLabel.text = "Wealth: $\(UsersInformation.wealthOfCurrentUser)"
        }
    }
    func determineEmailUsernameAndClass()
    {
        //if we don't manipulate now, all the buttons are visible for a moment before we observe
        manipulateOutlets(notInClass: true)
        if UsersInformation.currentUsersUsername == "X$29384uwalksefR!lsdkfa5%2412"
        {
            let ourActivityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
            ourActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
            ourActivityIndicator.hidesWhenStopped = true
            ourActivityIndicator.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/3, height: self.view.frame.width/3)
            ourActivityIndicator.center = self.view.center
            self.view.addSubview(ourActivityIndicator)
            ourActivityIndicator.startAnimating()
            UIApplication.shared.beginIgnoringInteractionEvents()
            UsersToReference.child("\(UsersInformation.currentUsersUID)").observeSingleEvent(of: .value, with: { (snapshot) in
                ourActivityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                if snapshot.exists() //just a little precaution
                {
                    let snapshotInJSONForm: [String : Any] = snapshot.value as! [String : Any]
                    UsersInformation.currentUsersUsername = snapshotInJSONForm["Username"]! as! String
                    if (snapshot.hasChild("ActiveClass"))
                    {
                        UsersInformation.weAreInClass = true
                        //they are in a class, download settings.
                        let thisClass:String = snapshotInJSONForm["ActiveClass"]! as! String
                        UsersInformation.classWeAreIn = thisClass
                        self.classReference = Database.database().reference(withPath: thisClass)
                        //show the correct icons.
                        print("First Timer Manipulation")
                        self.manipulateOutlets(notInClass: false)
                        self.observeEndDate()
                        self.findUsersResources()
                    }
                }
                else
                { // if for whatever reason we were unable to find that user, kick them out.
                    self.performSegue(withIdentifier: "backToSignIn", sender: nil)
                }
            })
        }
    }
    func observeEndDate()
    {
        /*
            I decided to observe the end date so that if the class wasn't active and it became active, we would know about it. 
        */
        Database.database().reference(withPath: UsersInformation.classWeAreIn).child("Information").observe(.value, with: { (snapshot) in
            if snapshot.exists()
            {
                print("1")
                let information = snapshot.value as! [String:Any]
                let ourEndDate:Int = information["EndDate"] as! Int;
                let settings = information["Settings"] as! [String:Bool]
                UsersInformation.settings = settings
                if ourEndDate != 0 //If the endDate does = 0, the class isn't active.
                {
                    if UsersInformation.classIsActive == false // added so this isn't repeated every xtime observe end date is called.
                    {
                        UsersInformation.classIsActive = true // represents activated
                        UsersInformation.endDateOfClass = ourEndDate
                        //set up timer to update time remaining.
                        self.ActivateLabel.text = "Time Remaining: ...."
                        _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateTimeRemaining), userInfo: nil, repeats: false)
                        self.UpdateLabelTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateTimeRemaining), userInfo: nil, repeats: true)
 
                        //Now that we have timer to update timer remaing, set up timer to end class
                        if (Int(truncating: NSNumber(value:Date().timeIntervalSince1970)) < UsersInformation.endDateOfClass) //if time is not over yet, then establish the timer.
                        {
                            print("Timer Established")
                            //this timer checks to see if our class has ended every 10 seconds.
                            _ = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { (Timer) in
                                let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
                                if currentDate > UsersInformation.endDateOfClass
                                {
                                    if UsersInformation.endDateOfClass != 0 //added because if you signout or leave class the endate was 0, and thus < currentdate, screen was showing.
                                    {
                                        self.transitionToEndScreen()
                                        Timer.invalidate()
                                    }
                                    else
                                    {
                                        Timer.invalidate()
                                    }
                                }
                            })
                        }
                        else //If the current date is larger than the end date of this class, then this class is over! Abort!
                        {
                            print("The class is over")
                            if UsersInformation.endDateOfClass != 0 //added because if you signout or leave class the endate was 0, and thus < currentdate, screen was showing.
                            {
                                self.transitionToEndScreen()
                            }
                            
                        }
                        //observeSingleEvent of everything else! All the stuff we need to function successfully.
                        UsersInformation.ActivationDate = information["ActivationDate"] as! Int;
                        UsersInformation.multiplier = information["Multiplier"] as! Float;
                        self.classReference.child("UsersMultipliers").child(UsersInformation.currentUsersUsername).observeSingleEvent(of: .value, with: { (snapshotFour) in
                            if snapshotFour.exists()
                            {
                                print("UsersMultipliers set.")
                                UsersInformation.individualResourceMultiplier = snapshotFour.value as! [String: Float]
                            }
                            else
                            {
                                //if this resource fails to load, it's because the class was just activated, so we know what our resource multiplier is anyways. Let's set that up. 
                                for element in UsersInformation.currentUsersActiveResources
                                {
                                    UsersInformation.individualResourceMultiplier["\(element)"] = UsersInformation.multiplier;
                                }
                            }
                        })
                    }
                }
            }
            else //If the end date doesn't exist at all, then the CLASS HAS BEEN DELETED**
            {
                print("Apparently this class has been deleted")
                UsersInformation.weAreInClass = false
                Database.database().reference(withPath: UsersInformation.classWeAreIn).child("Information").child("NumberOfDays").observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists()
                    {
                        self.joinClassLabel.isHidden = true
                        self.joinClassOutlet.isHidden = true
                        let alert = UIAlertController(title: "Error", message: "Unable to load your class, please try again later.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: { (action) in
                            self.dismiss(animated: true, completion: nil)
                        }))
                    }
                    else
                    {
                        self.UsersToReference.child(UsersInformation.currentUsersUID).child("ActiveClass").removeValue()
                        self.manipulateOutlets(notInClass: true)
                    }
                })
                
            }
        })

    }
    func findUsersResources()
    {
        print("Attempting to find Users Resources")
        //Even if the class isn't active, we need to get the User's resources, so lets observe that now.
        classReference.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() //just a little precaution
            {
                UsersInformation.currentUsersResources = snapshot.value as! [String: Int]
                UsersInformation.wealthOfCurrentUser = UsersInformation.currentUsersResources["Wealth"]!
                self.wealthLabel.text = "Wealth: $\(UsersInformation.wealthOfCurrentUser)"
                UsersInformation.currentUsersResources.removeValue(forKey: "Wealth")
                print("Users current Resource: \(UsersInformation.currentUsersResources)")
                for resource in UsersInformation.currentUsersResources
                {
                    if (resource.key.last == "X")
                    {
                        UsersInformation.currentUsersActiveResources.append(String(resource.key.dropLast()))
                    }
                }
                print("Users Active resource: \(UsersInformation.currentUsersActiveResources)")
            }
            else
            {
                print("unable to load user's resources, there is going to be an error on My Resources Page");
            }
        })
    }
    func manipulateOutlets(notInClass:Bool)
    {
        ActivateLabel.isHidden = notInClass
        BuildLabel.isHidden = notInClass
        BuildButton.isHidden = notInClass
        TradeLabel.isHidden = notInClass
        TradeButton.isHidden = notInClass
        ResourcesLabel.isHidden = notInClass
        ResourcesButton.isHidden = notInClass
        wealthLabel.isHidden = notInClass
        if (notInClass == false)
        {
            joinClassLabel.isHidden = true
            joinClassOutlet.isHidden = true
        }
        else
        {
            joinClassLabel.isHidden = !notInClass
            joinClassOutlet.isHidden = !notInClass
            
        }    
    }
    func transitionToEndScreen()
    {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "endScreen")
        let topController = UIApplication.topViewController()
        topController?.present(controller, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func joinClassDidTouch(_ sender: Any) {
        buttonSoundPlayer.play()
        performSegue(withIdentifier: "toJoinAClass", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.destination is leaderboardAndCredits
        {
            let nextViewController = segue.destination as? leaderboardAndCredits
            nextViewController?.leaderboard = leaderboard
        }
    }
    @objc func signOutDidTouch()
    {
        buttonSoundPlayer.play()
        var message = ""
        if UsersInformation.currentUsersUsername != "X$29384uwalksefR!lsdkfa5%2412"
        {
            message = "Current user: \(UsersInformation.currentUsersUsername)."
        }
        let alert = UIAlertController(title: "Sign out?", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
            UsersInformation.currentUsersUID = "Y"
            UsersInformation.currentUsersUsername = "X$29384uwalksefR!lsdkfa5%2412"
            UsersInformation.clickedUsersResources = [:]
            UsersInformation.currentUsersResources = [:]
            UsersInformation.clickedUsersActiveResources = []
            UsersInformation.currentUsersActiveResources = []
            UsersInformation.userWeAreTradingWith = "The Crabbster"
            UsersInformation.multiplier = 1.0
            UsersInformation.individualResourceMultiplier = [:]
            UsersInformation.theirIndividualResourceMultiplier = [:]
            UsersInformation.settings = [:]
            UsersInformation.wealthOfCurrentUser = 0
            UsersInformation.ActivationDate = 0
            UsersInformation.classWeAreIn = "Z"
            UsersInformation.weAreInClass = false
            UsersInformation.endDateOfClass = 0
            UsersInformation.firstTimeAround = true
            UsersInformation.classIsActive = false
            try! Auth.auth().signOut()
            self.performSegue(withIdentifier: "backToSignIn", sender: nil)
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }) )
        self.present(alert, animated: true, completion: nil)
   
    }
    @objc func leaderboardOrCredits(pressedButton:UIButton)
    {
        buttonSoundPlayer.play()
        if pressedButton.tag == 1
        {
            leaderboard = true
        }
        else
        {
            leaderboard = false
        }
        self.performSegue(withIdentifier: "toCredits", sender: nil)
    }
    @IBAction func TradeButtonWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        self.performSegue(withIdentifier: "toTradingScreen", sender: nil)
    }
    
    @IBAction func ResourceButtonWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        self.performSegue(withIdentifier: "toMyResources", sender: nil)
    }
    
    @IBAction func BuildButtonWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        self.performSegue(withIdentifier: "toBuildingScreen", sender: nil)
    }

    @IBAction func listButtonWasTouched(_ sender: Any) {
        slideSoundPlayer.play()
        let itemHeight:CGFloat = self.view.frame.height/12
        listButton.isHidden = true
        if UsersInformation.weAreInClass
        {
            numberOfButtons = 4
        }
        else
        {
            numberOfButtons = 3
            startingPoint = 1
        }
        let totalHeight = itemHeight * CGFloat(numberOfButtons)
        for i in startingPoint...numberOfButtons - 1
        {
            let nextButton:UIButton = UIButton()
            let backGroundLabel:UILabel = UILabel()
            backGroundLabel.text = ""
            backGroundLabel.backgroundColor = UIColor.lightGray
            backGroundLabel.layer.masksToBounds = true
            backGroundLabel.layer.cornerRadius = 5
            backGroundLabel.layer.borderWidth = 2
            backGroundLabel.layer.borderColor = UIColor.black.cgColor
            backGroundLabel.tag = i + 6
            backGroundLabel.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/3, height: itemHeight)
            backGroundLabel.center = CGPoint(x: 0 + backGroundLabel.frame.width/2, y: self.view.frame.height + (backGroundLabel.frame.height/2 + (backGroundLabel.frame.height * CGFloat(i)) + 2) )
            nextButton.frame = CGRect(x: 0, y: 0, width: backGroundLabel.frame.width - 6, height: itemHeight)
            nextButton.center = CGPoint(x: 0 + backGroundLabel.frame.width/2, y: self.view.frame.height + (nextButton.frame.height/2 + (nextButton.frame.height * CGFloat(i)) + 2) )
            nextButton.tag = i + 1
            nextButton.titleLabel?.adjustsFontSizeToFitWidth = true
            nextButton.setTitleColor(UIColor.darkGray, for: .normal)
            if i == 3
            {
                nextButton.setTitle("Leave Class", for: .normal)
                nextButton.addTarget(self, action: #selector(leaveClassWasTouched), for: .touchUpInside)
            }
            else if i == 2
            {
                nextButton.setTitle("Sign Out", for: .normal)
                nextButton.addTarget(self, action: #selector(signOutDidTouch), for: .touchUpInside)
            }
            else if i == 1
            {
                nextButton.setTitle("Credits", for: .normal)
                nextButton.addTarget(self, action: #selector(leaderboardOrCredits(pressedButton:)), for: .touchUpInside)
            }
            else if i == 0
            {
                nextButton.setTitle("Leaderboard", for: .normal)
                nextButton.addTarget(self, action: #selector(leaderboardOrCredits(pressedButton:)), for: .touchUpInside)
            }
            self.view.addSubview(backGroundLabel)
            self.view.addSubview(nextButton)
        }
        UIView.animate(withDuration: 0.3, animations: {
            for i in self.startingPoint...self.numberOfButtons - 1
            {
                let button:UIButton = self.view.viewWithTag(i + 1) as! UIButton
                let Label:UILabel = self.view.viewWithTag(i + 6) as! UILabel
                button.center = CGPoint(x: 0 + Label.frame.width/2, y: button.frame.midY - totalHeight )
                Label.center = CGPoint(x: 0 + Label.frame.width/2, y: Label.frame.midY - totalHeight )
            }
        }, completion: { (true) in
            self.sliderIsUp = true
        })
    }
    @objc func updateTimeRemaining()
    {
        let currentDate:Int = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
        var fakeTimeRemaining = UsersInformation.endDateOfClass - currentDate
        let days:Int = Int(fakeTimeRemaining / 86400)
        fakeTimeRemaining -= (days * 86400)
        let hours:Int = Int(fakeTimeRemaining / 3600)
        fakeTimeRemaining -= (hours * 3600)
        let minutes:Int = Int(fakeTimeRemaining / 60)
        self.ActivateLabel.text = "Time Remaining: \(days) Days, \(hours) Hours, and \(minutes) Minutes."
    }
    
    @objc func leaveClassWasTouched() {
    buttonSoundPlayer.play()
        //give them a warning with an alert. It would be nice to say what class they are in.
        let alert = UIAlertController(title: "Leave Class?", message: "Are you sure you want to leave this class?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
            //remove yourself from this class
            let tempClass = UsersInformation.classWeAreIn
            Database.database().reference(withPath: tempClass).child("NamesOfUsers").child(UsersInformation.currentUsersUsername).removeValue()
            Database.database().reference(withPath: tempClass).child("AllUserNames").child(UsersInformation.currentUsersUsername).setValue("Gone")
            Database.database().reference(withPath: tempClass).child("UsersMultipliers").child(UsersInformation.currentUsersUsername).removeValue()
            self.UsersToReference.child(UsersInformation.currentUsersUID).child("ActiveClass").removeValue()
            self.UpdateLabelTimer.invalidate()
            self.manipulateOutlets(notInClass: true)
            self.ActivateLabel.isHidden = true
            UsersInformation.weAreInClass = false
            UsersInformation.classWeAreIn = "Z"
            UsersInformation.classIsActive = false
            UsersInformation.endDateOfClass = 0
            UsersInformation.multiplier = 1.0
            UsersInformation.settings = [:]
            UsersInformation.userWeAreTradingWith = "The Crabbster"
            UsersInformation.currentUsersResources = [:]
            UsersInformation.currentUsersActiveResources = []
            UsersInformation.clickedUsersResources = [:]
            UsersInformation.currentUsersResources = [:]
            UsersInformation.individualResourceMultiplier = [:]
            UsersInformation.theirIndividualResourceMultiplier = [:]
            UsersInformation.ActivationDate = 0
            self.classReference = Database.database().reference(withPath: "nil")
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }) )
        self.present(alert, animated: true, completion: nil)
        dismissList()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if sliderIsUp
        {
            slideSoundPlayer.play()
            dismissList()
        }
    }
    func dismissList()
    {
        if (listButton.isHidden)
        {
            listButton.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                for i in self.startingPoint...self.numberOfButtons - 1
                {
                    let button:UIButton = self.view.viewWithTag(i + 1) as! UIButton
                    let Label:UILabel = self.view.viewWithTag(i + 6) as! UILabel
                    button.center = CGPoint(x: 0 + Label.frame.width/2, y: self.view.frame.height + (button.frame.height/2 + (button.frame.height * CGFloat(i)) + 2) )
                    Label.center = CGPoint(x: 0 + Label.frame.width/2, y: self.view.frame.height + (button.frame.height/2 + (button.frame.height * CGFloat(i)) + 2) )
                    
                }
            }, completion: { (true) in
                for i in self.startingPoint...self.numberOfButtons - 1
                {
                    let nextButton:UIButton = self.view.viewWithTag(i + 1) as! UIButton
                    let nextLabel:UILabel = self.view.viewWithTag(i + 6) as! UILabel
                    nextButton.removeFromSuperview()
                    nextLabel.removeFromSuperview()
                }
                self.numberOfButtons = 0
                self.sliderIsUp = false
            })
        }
        
    }
    
    

    @IBOutlet var listButton: UIButton!
    @IBOutlet var wealthLabel: UILabel!
    @IBOutlet var ActivateLabel: UILabel!
    @IBOutlet var BuildButton: UIButton!
    @IBOutlet var BuildLabel: UILabel!
    @IBOutlet var ResourcesButton: UIButton!
    @IBOutlet var ResourcesLabel: UILabel!
    @IBOutlet var TradeLabel: UILabel!
    @IBOutlet var TradeButton: UIButton!
    @IBOutlet var joinClassOutlet: UIButton!
    @IBOutlet var joinClassLabel: UILabel!
}

