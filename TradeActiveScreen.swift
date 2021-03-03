//
//  TradeActiveScreen.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 5/25/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class TradeActiveScreen:UIViewController {
    
    var allOfTheirResources: [String] = []
    var allOfOurResources: [String] = []
    var showValueOfTheirResource:UILabel = UILabel()
    var showValueOfOurResource:UILabel = UILabel()
    var theirResourceToGiveUp:String = ""
    var ourResourceToGiveUp:String = ""
    var theirResourceToAnimate:String = ""
    var ourResourceToAnimate:String = ""
    var theirPrevioulyPressedButton: UIButton = UIButton()
    var ourPreviouslyPressedButton: UIButton = UIButton()
    var numberOfResources:Int = 0
    var boxIsActive:Bool = false
    var increasingOurs:Bool = false
    var increasingTheirs:Bool = false
    var preventExtraLayouts:Bool = true
    let pot:UIButton = UIButton()
    var removebuttons:Timer = Timer()
    var removeTheirButtons:Timer = Timer()
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var AppluauseSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLayoutSubviews() {
        if preventExtraLayouts
        {
            preventExtraLayouts = false
            showValueOfTheirResource.center = CGPoint(x: self.view.frame.width/2, y: theirResourceAmountSelector.frame.minY - showValueOfTheirResource.frame.height/2)
            showValueOfOurResource.center = CGPoint(x: self.view.frame.width/2, y: ourResourceAmountSelector.frame.minY - showValueOfOurResource.frame.height/2)

        }
    }
    override func viewDidLoad() {
        //initialize sounds
        let buttonClickPath = Bundle.main.path(forResource: "buttonClick.mp3", ofType: nil)!
        let buttonClickSound = NSURL(fileURLWithPath: buttonClickPath)
        do {
            try buttonSoundPlayer = AVAudioPlayer(contentsOf: buttonClickSound as URL)
            buttonSoundPlayer.prepareToPlay()
        } catch {
        }
        let ApplauseClickPath = Bundle.main.path(forResource: "applause.mp3", ofType: nil)!
        let AppluaseSound = NSURL(fileURLWithPath: ApplauseClickPath)
        do {
            try AppluauseSoundPlayer = AVAudioPlayer(contentsOf: AppluaseSound as URL)
            AppluauseSoundPlayer.prepareToPlay()
        } catch {
        }
        let backTickPath = Bundle.main.path(forResource: "backTick.mp3", ofType: nil)!
        let backTickSound = NSURL(fileURLWithPath: backTickPath)
        do {
            try backTickSoundPlayer = AVAudioPlayer(contentsOf: backTickSound as URL)
            backTickSoundPlayer.prepareToPlay()
        } catch {
        }
        //initialize 
        showValueOfOurResource.isHidden = true
        showValueOfTheirResource.isHidden = true
        showValueOfTheirResource.backgroundColor = UIColor.gray
        showValueOfTheirResource.layer.masksToBounds = true
        showValueOfTheirResource.layer.cornerRadius = 5
        showValueOfTheirResource.textAlignment = .center
        showValueOfOurResource.backgroundColor = UIColor.gray
        showValueOfOurResource.layer.masksToBounds = true
        showValueOfOurResource.layer.cornerRadius = 5
        showValueOfOurResource.textAlignment = .center
        showValueOfTheirResource.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/4, height: self.view.frame.height/13)
        showValueOfTheirResource.adjustsFontSizeToFitWidth = true
        self.view.addSubview(showValueOfTheirResource)
        showValueOfOurResource.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/4, height: self.view.frame.height/13)
        showValueOfOurResource.adjustsFontSizeToFitWidth = true
            self.view.addSubview(showValueOfOurResource)
        //initialize the pot
        pot.isHidden = true
        pot.setTitle("The Pot", for: .normal)
        pot.titleLabel?.adjustsFontSizeToFitWidth = true
        pot.frame = CGRect(x: 0, y: 0, width: 4 * titleLabel.frame.height , height: 2 * titleLabel.frame.height)
        pot.center = CGPoint(x: self.view.frame.width - pot.frame.width/2 - 20, y: 0 + pot.frame.height/2 + 25)
        pot.backgroundColor = UIColor.lightGray
        pot.layer.masksToBounds = true
        pot.layer.cornerRadius = 5
        pot.addTarget(self, action: #selector(potWasTouched), for: .touchUpInside)
        self.view.addSubview(pot)
        
        //addTargetsToSliders
        ourResourceAmountSelector.addTarget(self, action: #selector(createOurTimer), for: .touchUpInside)
        ourResourceAmountSelector.addTarget(self, action: #selector(createOurTimer), for: .touchUpOutside)
        theirResourceAmountSelector.addTarget(self, action: #selector(createTheirTimer), for: .touchUpInside)
        theirResourceAmountSelector.addTarget(self, action: #selector(createTheirTimer), for: .touchUpOutside)
        titleLabel.text = "Trade with: \(UsersInformation.userWeAreTradingWith)"
        //initialize theirStackView
        Database.database().reference(withPath: UsersInformation.classWeAreIn).child("UsersMultipliers").child(UsersInformation.userWeAreTradingWith).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists()
            {
                UsersInformation.theirIndividualResourceMultiplier = snapshot.value as! [String:Float]
                self.populateStackViews(correctSelect: #selector(self.buttonWasSelected(pressedButton:)), correctStackView: self.theirResource, correctResources: UsersInformation.clickedUsersResources, correctAddingPoint: "Their")
                //initialize our Resources
                self.populateStackViews(correctSelect: #selector(self.ourButtonWasSelected(pressedButton:)), correctStackView: self.ourResource, correctResources: UsersInformation.currentUsersResources, correctAddingPoint: "Our")
                //if this is a adjust, adjust for it.
                if UsersInformation.adjustTrade.count != 0
                {
                    print("This is the apparent adjust trade we have: \(UsersInformation.adjustTrade)")
                    for trade in UsersInformation.adjustTrade
                    {
                        //determine what type of trade we're working with here, one we sent, or one they sent us.
                        let JSONDict:[String:Any] = trade.value
                        var TheirMessage:String = ""
                        var ourMessage:String = ""
                        if JSONDict["From"] as! String == UsersInformation.currentUsersUsername
                        {
                            TheirMessage = "ToSender"
                            ourMessage = "ToReceiver"
                            //give back our resources that are in the pot (So we can readjust with them).
                            if UsersInformation.currentUsersResources[JSONDict["Resource\(ourMessage)"] as! String] != nil || UsersInformation.currentUsersResources["\(JSONDict["Resource\(ourMessage)"] as! String)X"] != nil
                            {
                                var currentAmount:Int = 0
                                if UsersInformation.currentUsersActiveResources.contains(JSONDict["Resource\(ourMessage)"] as! String)
                                {
                                    currentAmount = UsersInformation.currentUsersResources["\(JSONDict["Resource\(ourMessage)"] as! String)X"]!
                                    currentAmount = currentAmount - (JSONDict["Amount\(ourMessage)"] as! Int)
                                    UsersInformation.currentUsersResources["\(JSONDict["Resource\(ourMessage)"] as! String)X"] = currentAmount
                                }
                                else
                                {
                                    currentAmount = UsersInformation.currentUsersResources[JSONDict["Resource\(ourMessage)"] as! String]!
                                    currentAmount = currentAmount + (JSONDict["Amount\(ourMessage)"] as! Int)
                                    UsersInformation.currentUsersResources[JSONDict["Resource\(ourMessage)"] as! String] = currentAmount
                                }
                                
                            }
                            else //if this resource does not exist, there is no way it is an active resource.
                            {
                                UsersInformation.currentUsersResources[JSONDict["Resource\(ourMessage)"] as! String] = (JSONDict["Amount\(ourMessage)"] as! Int)
                                //remove the views in there right now
                                for view in self.ourResource.subviews
                                {
                                    view.removeFromSuperview()
                                }
                                self.populateStackViews(correctSelect: #selector(self.ourButtonWasSelected(pressedButton:)), correctStackView: self.ourResource, correctResources: UsersInformation.currentUsersResources, correctAddingPoint: "Our")
                            }
                        }
                        else
                        {
                            TheirMessage = "ToReceiver"
                            ourMessage = "ToSender"
                            print("Their resources: \(UsersInformation.clickedUsersResources)")
                            //Give back their resources that are in their pot.
                            if UsersInformation.clickedUsersResources[JSONDict["Resource\(TheirMessage)"] as! String] != nil || UsersInformation.clickedUsersResources["\(JSONDict["Resource\(TheirMessage)"] as! String)X"] != nil
                            {
                                var currentAmount:Int = 0
                                if UsersInformation.clickedUsersActiveResources.contains(JSONDict["Resource\(TheirMessage)"] as! String)
                                {
                                    currentAmount = UsersInformation.clickedUsersResources[JSONDict["Resource\(TheirMessage)"] as! String]!
                                    currentAmount = currentAmount - (JSONDict["Amount\(TheirMessage)"] as! Int)
                                    UsersInformation.clickedUsersResources[JSONDict["Resource\(TheirMessage)"] as! String] = currentAmount
                                }
                                else
                                {
                                    currentAmount = UsersInformation.clickedUsersResources[JSONDict["Resource\(TheirMessage)"] as! String]!
                                    currentAmount = currentAmount + (JSONDict["Amount\(TheirMessage)"] as! Int)
                                    UsersInformation.clickedUsersResources[JSONDict["Resource\(TheirMessage)"] as! String] = currentAmount
                                }
                                
                            }
                            else //if this resource does not exist, there is no way it is an active resource.
                            {
                                UsersInformation.clickedUsersResources[JSONDict["Resource\(TheirMessage)"] as! String] = (JSONDict["Amount\(TheirMessage)"] as! Int)
                                //remove the views in there right now
                                for view in self.theirResource.subviews
                                {
                                    view.removeFromSuperview()
                                }
                                print("4")
                                self.populateStackViews(correctSelect: #selector(self.buttonWasSelected(pressedButton:)), correctStackView: self.theirResource, correctResources: UsersInformation.clickedUsersResources, correctAddingPoint: "Their")
                            }
                            
                        }
                        
                        //select the correct buttons.
                        var i = 1
                        for resource in UsersInformation.clickedUsersResources
                        {
                            if resource.key == JSONDict["Resource\(TheirMessage)"] as! String
                            {
                                let button:UIButton = self.theirResource.viewWithTag(i) as! UIButton
                                self.buttonWasSelected(pressedButton: button)
                            }
                            i = i + 1
                        }
                        i = 21
                        for resource in UsersInformation.currentUsersResources
                        {
                            if resource.key == JSONDict["Resource\(ourMessage)"] as! String || resource.key == "\(JSONDict["Resource\(ourMessage)"] as! String)X"
                            {
                                let button:UIButton = self.ourResource.viewWithTag(i) as! UIButton
                                self.ourButtonWasSelected(pressedButton: button)
                            }
                            i = i + 1
                        }
                        self.theirResourceAmountSelector.value = Float(JSONDict["Amount\(TheirMessage)"] as! Int)
                        self.ourResourceAmountSelector.value = Float(JSONDict["Amount\(ourMessage)"] as! Int)
                    } 
                    self.titleLabel.text = "Adjust trade with: \(UsersInformation.userWeAreTradingWith)"
                    self.offerTradeLabel.text = "Adjust Trade"
                }
                else
                {
                    let theirFirstButton:UIButton = self.theirResource.viewWithTag(1) as! UIButton
                    self.buttonWasSelected(pressedButton: theirFirstButton)
                    let ourFirstButton:UIButton = self.ourResource.viewWithTag(21) as! UIButton
                    self.ourButtonWasSelected(pressedButton: ourFirstButton)
                }

            }
        })

    }
    func populateStackViews(correctSelect: Selector, correctStackView: UIStackView, correctResources: [String : Int], correctAddingPoint:String)
    {
        for resource in correctResources
        {
            var resourceImage:UIImage = UIImage()
            if correctAddingPoint == "Our"{
                allOfOurResources.append(resource.key)
            }
            else{
                allOfTheirResources.append(resource.key)
            }
            let verticalStackView:UIStackView = UIStackView()
            verticalStackView.axis = .vertical
            verticalStackView.alignment = .center
            verticalStackView.distribution = .equalSpacing
            if resource.key.last == "X"
            {
                resourceImage = UIImage(named: "resource\(String(resource.key.dropLast()))")!
            }
            else{
                resourceImage = UIImage(named: "resource\(resource.key)")!
            }
            let resourceButton:UIButton = UIButton()
            resourceButton.setImage(resourceImage, for: .normal)
            resourceButton.alpha = 0.4
            resourceButton.addTarget(self, action: correctSelect, for: .touchUpInside)
            resourceButton.contentMode = .scaleAspectFit
            if correctAddingPoint == "Our"{
                resourceButton.tag = correctStackView.arrangedSubviews.count + 21
            }
            else{
                resourceButton.tag = correctStackView.arrangedSubviews.count + 1
            }
            let resourceDescription:UILabel = UILabel()
            if correctAddingPoint == "Our" && UsersInformation.currentUsersActiveResources.contains(String(resource.key.dropLast()))
            {
                resourceDescription.text = String(resource.key.dropLast())
            }
            else{
                resourceDescription.text = resource.key
            }
            resourceDescription.textAlignment = .center
            resourceDescription.textColor = UIColor.black
            resourceDescription.adjustsFontSizeToFitWidth = true
            verticalStackView.addArrangedSubview(resourceButton)
            verticalStackView.addArrangedSubview(resourceDescription)
            correctStackView.addArrangedSubview(verticalStackView)
        }
    }

    @IBAction func backButtonWasPressed(_ sender: Any) {
        backTickSoundPlayer.play()
        UsersInformation.userWeAreTradingWith = ""
        if UsersInformation.adjustTrade.count != 0
        {
            for trade in UsersInformation.adjustTrade
            {
                let JSONDict:[String:Any] = trade.value
                if JSONDict["From"] as! String == UsersInformation.currentUsersUsername
                {
                    //take back our resources that we removed from the pot to adjust this, and now put them back because we are cancelling.
                    var currentAmount:Int = 0
                    if UsersInformation.currentUsersActiveResources.contains(JSONDict["ResourceToReceiver"] as! String)
                    {
                        currentAmount = UsersInformation.currentUsersResources["\(JSONDict["ResourceToReceiver"] as! String)X"]!
                        currentAmount = currentAmount + (JSONDict["AmountToReceiver"] as! Int)
                        UsersInformation.currentUsersResources["\(JSONDict["ResourceToReceiver"] as! String)X"] = currentAmount
                    }
                    else
                    {
                        currentAmount = UsersInformation.currentUsersResources[JSONDict["ResourceToReceiver"] as! String]!
                        currentAmount = currentAmount - (JSONDict["AmountToReceiver"] as! Int)
                        UsersInformation.currentUsersResources[JSONDict["ResourceToReceiver"] as! String] = currentAmount
                    }
                }
            }
            
            UsersInformation.adjustTrade = [:]
            self.performSegue(withIdentifier: "backToActives", sender: nil)
        }
        else
        {
            self.performSegue(withIdentifier: "backToTradeScreen", sender: nil)   
        }
        
    }
    @objc func buttonWasSelected(pressedButton: UIButton)
    {
        buttonSoundPlayer.play()
        theirResourceToGiveUp = allOfTheirResources[pressedButton.tag - 1]
        theirPrevioulyPressedButton.alpha = 0.4
        theirPrevioulyPressedButton = pressedButton
        pressedButton.alpha = 1
        if UsersInformation.clickedUsersActiveResources.contains(theirResourceToGiveUp)
        {
            let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
                let valueOfResource = Int(Float(currentDate - (UsersInformation.ActivationDate + UsersInformation.clickedUsersResources["\(theirResourceToGiveUp)"]!)) * UsersInformation.theirIndividualResourceMultiplier[theirResourceToGiveUp]!)
                theirResourceAmountSelector.maximumValue = Float(valueOfResource)
            
        }
        else
        {
            theirResourceAmountSelector.maximumValue = Float(UsersInformation.clickedUsersResources[theirResourceToGiveUp]!)
        }
    }
    
    @objc func ourButtonWasSelected(pressedButton: UIButton)
    {
        buttonSoundPlayer.play()
        print(allOfOurResources)
        ourResourceToGiveUp = allOfOurResources[pressedButton.tag - 21]
        ourPreviouslyPressedButton.alpha = 0.4
        ourPreviouslyPressedButton = pressedButton
        pressedButton.alpha = 1
        let resourceWithoutX:String = String(ourResourceToGiveUp.dropLast())
        if UsersInformation.currentUsersActiveResources.contains(resourceWithoutX)
        {
            let currentDate:Int = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
            let valueOfResource = Int(Float(currentDate - (UsersInformation.ActivationDate + UsersInformation.currentUsersResources[ourResourceToGiveUp]!)) * UsersInformation.individualResourceMultiplier[String(ourResourceToGiveUp.dropLast())]!)
            ourResourceAmountSelector.maximumValue = Float(valueOfResource)
            
        }
        else
        {
            ourResourceAmountSelector.maximumValue = Float(UsersInformation.currentUsersResources[ourResourceToGiveUp]!)
        }
        
    }
    
    @IBAction func showValueOfOurResource(_ sender: Any) {
        showValueOfOurResource.isHidden = false
        let roundedValue:Int = Int(ourResourceAmountSelector.value + 5)/10 * 10
        showValueOfOurResource.text = "\(roundedValue)"
        createAdjustButtons(ours: true, label: showValueOfOurResource)
    }
    @IBAction func showValueOfTheirResource(_ sender: Any) {
        showValueOfTheirResource.isHidden = false
        let roundedValue:Int = Int(theirResourceAmountSelector.value + 5)/10 * 10
        showValueOfTheirResource.text = "\(roundedValue)"
        createAdjustButtons(ours: false, label: showValueOfTheirResource)
    }
    func createTimer(theTimer:inout Timer, ours:Bool)
    {
        if theTimer.isValid
        {
            theTimer.invalidate()
        }
        theTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(deleteButtons), userInfo: ["Ours": ours], repeats: false)
    }
    @objc func createOurTimer()
    {
        createTimer(theTimer: &removebuttons, ours: true)
    }
    @objc func createTheirTimer()
    {
        createTimer(theTimer: &removeTheirButtons, ours: false)
    }
    @objc func deleteButtons(timer:Timer)
    {
        let userInfo = timer.userInfo as! [String:Any]
        let isOurs:Bool = userInfo["Ours"] as! Bool
        if (isOurs)
        {
            let decreasingButton:UIButton = self.view.viewWithTag(129) as! UIButton
            let increasingButton:UIButton = self.view.viewWithTag(130) as! UIButton
            decreasingButton.removeFromSuperview()
            increasingButton.removeFromSuperview()
            showValueOfOurResource.isHidden = true
            increasingOurs = false
        }
        else
        {
            let decreasingButton:UIButton = self.view.viewWithTag(131) as! UIButton
            let increasingButton:UIButton = self.view.viewWithTag(132) as! UIButton
            decreasingButton.removeFromSuperview()
            increasingButton.removeFromSuperview()
            showValueOfTheirResource.isHidden = true
            increasingTheirs = false
        }
    }
    func createAdjustButtons(ours:Bool, label:UILabel)
    {
        if ((ours && !increasingOurs) || (!ours && !increasingTheirs))
        {
            let decreaseButton:UIButton = UIButton()
            let ButtonImage:UIImage = UIImage(named: "upAndDownArrow")!
            let flipedCountryImage:UIImage = UIImage(cgImage: ButtonImage.cgImage!, scale: ButtonImage.scale, orientation: UIImageOrientation.rightMirrored)
            decreaseButton.setImage(flipedCountryImage, for: .normal)
            let buttonWidth:CGFloat = self.view.frame.width/7
            decreaseButton.frame = CGRect(x: label.frame.minX - 5 - buttonWidth, y: label.frame.minY, width: buttonWidth, height: label.frame.height)
            let increaseButton:UIButton = UIButton()
            let otherWayFlipped:UIImage = UIImage(cgImage: ButtonImage.cgImage!, scale: ButtonImage.scale, orientation: UIImageOrientation.leftMirrored)
            increaseButton.setImage(otherWayFlipped, for: .normal)
            increaseButton.frame = CGRect(x: label.frame.maxX + 5, y: label.frame.minY, width: buttonWidth, height: label.frame.height)
            if (ours)
            {
                increasingOurs = true
                decreaseButton.tag = 129
                increaseButton.tag = 130
                decreaseButton.addTarget(self, action: #selector(decreaseOurAmount), for: .touchUpInside)
                increaseButton.addTarget(self, action: #selector(increaseOurAmount), for: .touchUpInside)
            }
            else
            {
                increasingTheirs = true
                decreaseButton.tag = 131
                increaseButton.tag = 132
                decreaseButton.addTarget(self, action: #selector(decreaseTheirAmount), for: .touchUpInside)
                increaseButton.addTarget(self, action: #selector(increaseTheirAmount), for: .touchUpInside)
            }
            self.view.addSubview(increaseButton)
            self.view.addSubview(decreaseButton)
        }
    }
    @objc func decreaseTheirAmount()
    {
        let whatIsFive:Float = theirResourceAmountSelector.value - 10
        theirResourceAmountSelector.setValue(whatIsFive, animated: false)
        showValueOfTheirResource(self)
        createTheirTimer()
    }
    @objc func increaseTheirAmount()
    {
        let whatIsFive:Float = theirResourceAmountSelector.value + 10
        theirResourceAmountSelector.setValue(whatIsFive, animated: false)
        showValueOfTheirResource(self)
        createTheirTimer()
    }
    @objc func decreaseOurAmount()
    {
        let whatIsFive:Float = ourResourceAmountSelector.value - 10
        ourResourceAmountSelector.setValue(whatIsFive, animated: false)
        showValueOfOurResource(self)
        createOurTimer()
        
    }
    @objc func increaseOurAmount()
    {
        let whatIsFive:Float = ourResourceAmountSelector.value + 10
        ourResourceAmountSelector.setValue(whatIsFive, animated: false)
        showValueOfOurResource(self)
        createOurTimer()
    }
    
    
    //make the trade
    @IBAction func makeTheTrade(_ sender: Any) {
        let ourResourceToGiveUpEdited:String = determineIfLastCharacterIsX(stringToCheck: ourResourceToGiveUp)
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
        var newValueOfResource:Int = 0
        let theirRoundedValue:Int = Int(theirResourceAmountSelector.value + 5)/10 * 10
        let ourRoundedValue:Int = Int(ourResourceAmountSelector.value + 5)/10 * 10
        let alert = UIAlertController(title: "Confirm Trade", message: "Are you sure you want to trade \(ourRoundedValue) of your \(ourResourceToGiveUpEdited), for \(theirRoundedValue) of \(UsersInformation.userWeAreTradingWith)'s \(theirResourceToGiveUp)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
            self.AppluauseSoundPlayer.play()
            //if this is an adjust, adjust for it.
            if UsersInformation.adjustTrade.count != 0
            {
                for trade in UsersInformation.adjustTrade
                {
                    //remove Trade
                    ref.child("Trades").child(trade.key).removeValue()
                    let OldTrade:[String:Any] = trade.value
                    print(OldTrade)
                    if (OldTrade["To"] as! String == UsersInformation.currentUsersUsername) //The trade came to us from them, and we're adjusting it.
                    {
                        //reset their resources, with the stuff from the pot back in their possession.
                        //I had to reobserve this data because our clicked users resource doesn't have X's on it.
                        //This also makes it impossible that they changed their resources, And we set them back to what they were.
                        ref.child("NamesOfUsers").child(UsersInformation.userWeAreTradingWith).observeSingleEvent(of: .value, with: { (snapshotX) in
                            let TheirActualResources:[String:Int] = snapshotX.value as! [String:Int]
                            var found = false
                            for resource in TheirActualResources //find out if the resource they gave us is active or not, and if they still have it all
                            {
                                print(resource.key)
                                if OldTrade["ResourceToReceiver"] as! String == resource.key || "\(OldTrade["ResourceToReceiver"] as! String)X" == resource.key
                                {
                                    found = true
                                    var newValue:Int = resource.value
                                    if resource.key.last == "X"
                                    {
                                        newValue = newValue - (OldTrade["AmountToReceiver"] as! Int)
                                        ref.child("NamesOfUsers").child(UsersInformation.userWeAreTradingWith).child("\(OldTrade["ResourceToReceiver"] as! String)X").setValue(newValue)
                                    }
                                    else
                                    {
                                        newValue = newValue + (OldTrade["AmountToReceiver"] as! Int)
                                        ref.child("NamesOfUsers").child(UsersInformation.userWeAreTradingWith).child(OldTrade["ResourceToReceiver"] as! String).setValue(newValue)
                                    }
                                }
                            }
                            if found == false //They gave us everything to us.... So reset that.
                            {
                                ref.child("NamesOfUsers").child(UsersInformation.userWeAreTradingWith).child(OldTrade["ResourceToReceiver"] as! String).setValue(OldTrade["AmountToReceiver"] as! Int)
                            }
                        })
                    }
                }
                //old trade completely removed, begin new trade....
            }
            //remove our Resources
            var ResourceToSend:String = ""
            if self.ourResourceToGiveUp.last == "X"
            {
                newValueOfResource = UsersInformation.currentUsersResources[self.ourResourceToGiveUp]! + ourRoundedValue
                UsersInformation.currentUsersResources[self.ourResourceToGiveUp]! = newValueOfResource
                ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child(self.ourResourceToGiveUp).setValue(newValueOfResource)
                ResourceToSend = String(self.ourResourceToGiveUp.dropLast())
            }
            else
            {
                newValueOfResource = UsersInformation.currentUsersResources[self.ourResourceToGiveUp]! - ourRoundedValue
                UsersInformation.currentUsersResources[self.ourResourceToGiveUp]! = newValueOfResource
                if newValueOfResource != 0
                {
                    ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child(self.ourResourceToGiveUp).setValue(newValueOfResource)
                }
                else
                {
                    ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child(self.ourResourceToGiveUp).removeValue()
                    UsersInformation.currentUsersResources.removeValue(forKey: "\(self.ourResourceToGiveUp)")
                    self.allOfOurResources = self.allOfOurResources.filter {$0 != self.ourResourceToGiveUp}
                }
                ResourceToSend = self.ourResourceToGiveUp
            }
            let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
            let JSONDict:[String:Any] = ["From": UsersInformation.currentUsersUsername, "To": UsersInformation.userWeAreTradingWith, "ResourceToReceiver": ResourceToSend, "ResourceToSender": self.theirResourceToGiveUp, "AmountToReceiver": ourRoundedValue, "AmountToSender": theirRoundedValue, "Active": 0, "timeSent": currentDate]
            //add to active trades
            ref.child("Trades").childByAutoId().setValue(JSONDict)
            //do some appealing looking stuff.
            self.ourResourceToAnimate = self.determineIfLastCharacterIsX(stringToCheck: self.ourResourceToGiveUp)
            self.theirResourceToAnimate = self.determineIfLastCharacterIsX(stringToCheck: self.theirResourceToGiveUp)
            self.animateTrade()
            for view in self.ourResource.subviews
            {
                view.removeFromSuperview()
            }
            self.populateStackViews(correctSelect: #selector(self.ourButtonWasSelected(pressedButton:)), correctStackView: self.ourResource, correctResources: UsersInformation.currentUsersResources, correctAddingPoint: "Our")
            self.theirPrevioulyPressedButton.alpha = 0.4
            self.ourResourceAmountSelector.value = 0
            self.theirResourceAmountSelector.value = 0
            //reselect first buttons.
            let theirFirstButton:UIButton = self.theirResource.viewWithTag(1) as! UIButton
            self.buttonWasSelected(pressedButton: theirFirstButton)
            let ourFirstButton:UIButton = self.ourResource.viewWithTag(21) as! UIButton
            self.ourButtonWasSelected(pressedButton: ourFirstButton)
        })) //end of accept button
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction) in
        alert.dismiss(animated: true, completion: nil)
        }) )
        self.present(alert, animated: true, completion: nil)
    }
    @objc func animateTrade()
    {
        if numberOfResources < 2
        {
            _ = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(animateTrade), userInfo: nil, repeats: false)
            numberOfResources += 1
        }
        else
        {
            numberOfResources = 0
        }
        let ourImageToAnimate = UIImageView()
        let theirImageToAnimate = UIImageView()
        ourImageToAnimate.image = UIImage(named: "resource\(ourResourceToAnimate)")
        ourImageToAnimate.contentMode = .scaleAspectFit
        ourImageToAnimate.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/4, height: self.view.frame.height/6)
        ourImageToAnimate.center = CGPoint(x: ourResource.frame.midX, y: ourResource.frame.midY)
        theirImageToAnimate.image = UIImage(named: "resource\(theirResourceToAnimate)")
        theirImageToAnimate.contentMode = .scaleAspectFit
        theirImageToAnimate.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/4, height: self.view.frame.height/6)
        theirImageToAnimate.center = CGPoint(x: theirResource.frame.midX, y: theirResource.frame.midY)
        self.view.addSubview(ourImageToAnimate)
        self.view.addSubview(theirImageToAnimate)
        pot.isHidden = false
       UIView.animate(withDuration: 0.75) {
            ourImageToAnimate.frame = CGRect(x: self.pot.frame.midX, y: self.pot.frame.midY, width: 0, height: 0)
            theirImageToAnimate.frame = CGRect(x: self.pot.frame.midX, y: self.pot.frame.midY, width: 0, height: 0)
        }
        
    }
    func determineIfLastCharacterIsX(stringToCheck:String) -> String
    {
        var stringEdited:String = ""
        if stringToCheck.last == "X"
        {
            stringEdited = String(stringToCheck.dropLast())
        }
        else
        {
            stringEdited = stringToCheck
        }
        return stringEdited
    }
    @objc func potWasTouched()
    {
        buttonSoundPlayer.play()
        boxIsActive = true
        let boxThing:UIImageView = UIImageView()
        boxThing.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/2, height: self.view.frame.height/3)
        boxThing.center = CGPoint(x: self.view.frame.width - boxThing.frame.width/2 - 16, y: boxThing.frame.height/2 + 20)
        boxThing.tag = 921
        let boxThingImage = UIImage(named: "greyBox")
        boxThing.image = boxThingImage
        //initialize label
        let InformativeLabel:UILabel = UILabel()
        InformativeLabel.adjustsFontSizeToFitWidth = true
        InformativeLabel.textAlignment = .center
        InformativeLabel.numberOfLines = 0
        InformativeLabel.frame = CGRect(x: 0, y: 0, width: boxThing.frame.width - 10, height: boxThing.frame.height - 20)
        InformativeLabel.tag = 922
        InformativeLabel.center = CGPoint(x: boxThing.frame.midX, y: boxThing.frame.midY)
        InformativeLabel.text = "Resources you have offered up for trade, are removed from you and put into the pot. If the trade is declined you will have them returned."
        self.view.addSubview(boxThing)
        self.view.addSubview(InformativeLabel)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if boxIsActive
        {
            boxIsActive = false
            let button = self.view.viewWithTag(921)
            button?.removeFromSuperview()
            let label = self.view.viewWithTag(922)
            label?.removeFromSuperview()
        }
    }
    

    @IBOutlet var offerTradeLabel: UILabel!
    @IBOutlet var ourResource: UIStackView!
    @IBOutlet var theirResource: UIStackView!
    @IBOutlet var theirResourceAmountSelector: UISlider!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var ourResourceAmountSelector: UISlider!
    
    
}
