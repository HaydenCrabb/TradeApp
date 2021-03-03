//
//  activeTrades.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 6/1/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class activeTrades: UIViewController{
    
    var allTrades: [String: [String:Any]] = [:]
    var finishedTrades: [String:[String:Any]] = [:]
    var ButtonInView:Int = 1
    var paddingSpace:CGFloat = 0
    var allTradesKeys:[String] = []
    var containersArray: [UIView] = []
    let ourActivityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var applauseSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        //initialize audio
        let buttonClickPath = Bundle.main.path(forResource: "buttonClick.mp3", ofType: nil)!
        let buttonClickSound = NSURL(fileURLWithPath: buttonClickPath)
        let ApplausePath = Bundle.main.path(forResource: "applause.mp3", ofType: nil)!
        let ApplauseSound = NSURL(fileURLWithPath: ApplausePath)
        do {
            try buttonSoundPlayer = AVAudioPlayer(contentsOf: buttonClickSound as URL)
            buttonSoundPlayer.prepareToPlay()
        } catch {
            print("Bummer....")
        }
        do {
            try applauseSoundPlayer = AVAudioPlayer(contentsOf: ApplauseSound as URL)
            applauseSoundPlayer.prepareToPlay()
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
        //flip upArrow
        upArrow.isHidden = true
        downArrow.isHidden = true
        let ButtonImage:UIImage = UIImage(named: "upAndDownArrow")!
        let flipedCountryImage:UIImage = UIImage(cgImage: ButtonImage.cgImage!, scale: ButtonImage.scale, orientation: UIImageOrientation.downMirrored)
        upArrow.setBackgroundImage(flipedCountryImage, for: .normal)
        //create activty indicator
        ourActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        ourActivityIndicator.hidesWhenStopped = true
        ourActivityIndicator.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/3, height: self.view.frame.width/3)
        ourActivityIndicator.center = self.view.center
        self.view.addSubview(ourActivityIndicator)
        createActivityIndicator()
        discoverTrades(populatingActiveTrades: true)
    }
    func createActivityIndicator()
    {
        ourActivityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    func removeActivityIndicator()
    {
        ourActivityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    
    func discoverTrades(populatingActiveTrades:Bool)
    {
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
        ref.child("Trades").queryOrdered(byChild: "To").queryEqual(toValue: "\(UsersInformation.currentUsersUsername)").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists()
            {
               // self.noActivesLabel.isHidden = true
                self.allTrades = snapshot.value as! [String : [String:Any]]
                for trade in self.allTrades
                {
                    let JSONDict:[String:Any] = trade.value
                    if JSONDict["Active"] as! Int != 0
                    {
                        self.finishedTrades[trade.key] = trade.value
                        self.allTrades[trade.key] = nil
                    }
                }
            }
            ref.child("Trades").queryOrdered(byChild: "From").queryEqual(toValue: UsersInformation.currentUsersUsername).observeSingleEvent(of: .value, with: { (snapshot) in
                self.removeActivityIndicator()
                if snapshot.exists()
                {
                    let tradesFromUs = snapshot.value as! [String:[String:Any]]
                    for trade in tradesFromUs
                    {
                        let JSONDict:[String:Any] = trade.value
                        if JSONDict["Active"] as! Int == 0
                        {
                            self.allTrades[trade.key] = trade.value
                        }
                        else
                        {
                            self.finishedTrades[trade.key] = trade.value
                        }
                    }
                }
                if (populatingActiveTrades)
                {
                   self.popluateInOrder(dict: &self.allTrades, dealingWithActiveTrades: populatingActiveTrades)
                }
                else
                {
                    self.popluateInOrder(dict: &self.finishedTrades, dealingWithActiveTrades: populatingActiveTrades)
                }
                
                self.whichButtonsAreNeeded()
                self.HideAppropriateViews()
                self.checkIfWeHaveTrades()
            })
        })
    }
    func populateStackView(JSONDict:[String:Any], numberOfOurTrades: Int, isOurTrade:Bool, dealingWithActiveTrades:Bool)
    {
        /*we've got multiple active trades, and multiple different accept decline and adjust buttons,
        so in order to identify which trade we have accepted/declined/ect we count the number of active trades, and give each button that corresponding tag.
         */
        //determine how much space we have.
        let totalDistance:CGFloat = downArrow.frame.minY - upArrow.frame.maxY
        let containerSize:CGFloat = totalDistance/2.2
        let padding:CGFloat = (containerSize * 0.1) / 3
        paddingSpace = (totalDistance - (containerSize * 2))/4
        let isSecondContainer:Int = numberOfOurTrades - 1
        let normalCenter:CGFloat = (upArrow.frame.maxY + paddingSpace + (containerSize/2))
        let centerPlusNumberOfTrades:CGFloat = ((paddingSpace * 2) * CGFloat(isSecondContainer)) + (containerSize * CGFloat(isSecondContainer))
        
        /*Of Total Height
        padding 10%
        top two labels 25%
        bottom buttons 20%
        images 45%
        */
        let container:UIView = UIView()
        container.frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 40, height: containerSize)
        container.center = CGPoint(x: self.view.frame.midX, y: (normalCenter + centerPlusNumberOfTrades))
        container.tag = numberOfOurTrades
        
        
        //identifier stackView
        let nameStackView:UIStackView = UIStackView()
        nameStackView.axis = .horizontal
        nameStackView.alignment = .fill
        nameStackView.distribution = .equalSpacing
        nameStackView.frame = CGRect(x: 0, y: 0, width: container.frame.width, height: containerSize * 0.125)
        nameStackView.tag = numberOfOurTrades
        
        let yourNameLabel:UILabel = UILabel()
        yourNameLabel.textAlignment = .left
        yourNameLabel.adjustsFontSizeToFitWidth = true
        yourNameLabel.tag = numberOfOurTrades
        
        let theirNameLabel:UILabel = UILabel()
        theirNameLabel.textAlignment = .right
        theirNameLabel.adjustsFontSizeToFitWidth = true
        theirNameLabel.tag = numberOfOurTrades
        
        let status:UILabel = UILabel()
        status.textAlignment = .center
        status.adjustsFontSizeToFitWidth = true
        status.tag = numberOfOurTrades
        if (JSONDict["Active"] as! Int == 1)
        {
            status.text = "Accepted"
            status.textColor = UIColor(displayP3Red: 0.36, green: 0.79, blue: 0.38, alpha: 1)
        }
        else if (JSONDict["Active"] as! Int) == 2
        {
            status.text = "Declined"
            status.textColor = UIColor.red
        }
        else
        {
            if (isOurTrade)
            {
                status.text = "Offered"
            }
        }
        
        nameStackView.addArrangedSubview(yourNameLabel)
        nameStackView.addArrangedSubview(status)
        nameStackView.addArrangedSubview(theirNameLabel)
        
        //amout stack view
        let amountStackView:UIStackView = UIStackView()
        amountStackView.axis = .horizontal
        amountStackView.alignment = .fill
        amountStackView.distribution = .equalSpacing
        amountStackView.frame = CGRect(x: 0, y: nameStackView.frame.maxY + padding, width: container.frame.width, height: containerSize * 0.125)
        amountStackView.tag = numberOfOurTrades
        
        let yourAmountLabel:UILabel = UILabel()
        yourAmountLabel.textAlignment = .left
        yourAmountLabel.adjustsFontSizeToFitWidth = true
        yourAmountLabel.tag = numberOfOurTrades
        
        let theirAmountLabel:UILabel = UILabel()
        theirAmountLabel.textAlignment = .right
        theirAmountLabel.adjustsFontSizeToFitWidth = true
        theirAmountLabel.tag = numberOfOurTrades
        
        amountStackView.addArrangedSubview(yourAmountLabel)
        amountStackView.addArrangedSubview(theirAmountLabel)
        
        //images
        let imageStackView:UIStackView = UIStackView()
        imageStackView.axis = .horizontal
        imageStackView.alignment = .fill
        imageStackView.distribution = .fillEqually
        imageStackView.frame = CGRect(x: 0, y: amountStackView.frame.maxY + padding, width: container.frame.width, height: containerSize * 0.45)
        imageStackView.tag = numberOfOurTrades
        
        let ourResourceToGive:UIImageView = UIImageView()
        ourResourceToGive.contentMode = .scaleAspectFit
        
        let arrowsImage:UIImageView = UIImageView()
        arrowsImage.image = UIImage(named: "tradeArrows")
        arrowsImage.contentMode = .scaleAspectFit
        arrowsImage.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/5, height: self.view.frame.width/9)
        
        let theirResourceToGive:UIImageView = UIImageView()
        theirResourceToGive.contentMode = .scaleAspectFit
        
        imageStackView.addArrangedSubview(ourResourceToGive)
        imageStackView.addArrangedSubview(arrowsImage)
        imageStackView.addArrangedSubview(theirResourceToGive)
        
        
        let buttonContainer:UIStackView = UIStackView()
        //Button stackView
        buttonContainer.axis = .horizontal
        buttonContainer.alignment = .fill
        buttonContainer.distribution = .equalSpacing
        buttonContainer.frame = CGRect(x: 0, y: imageStackView.frame.maxY + padding, width: container.frame.width, height: containerSize * 0.2)
        buttonContainer.tag = numberOfOurTrades
        
        let darkGrey = UIColor(displayP3Red: 35/255, green: 31/255, blue: 32/255, alpha: 1)
        //make buttons depending on who sent the trade
        if (isOurTrade)
        {
            yourNameLabel.text = "You"
            theirNameLabel.text = "\(JSONDict["To"] as! String)"
            ourResourceToGive.image = UIImage(named: "resource\(JSONDict["ResourceToReceiver"] as! String)")
            theirResourceToGive.image = UIImage(named: "resource\(JSONDict["ResourceToSender"] as! String)")
            yourAmountLabel.text = "\(JSONDict["AmountToReceiver"] as! Int) \(JSONDict["ResourceToReceiver"] as! String)"
            theirAmountLabel.text = "\(JSONDict["AmountToSender"] as! Int) \(JSONDict["ResourceToSender"] as! String)"
            
            if (dealingWithActiveTrades)
            {
                let removeButton:UIButton = UIButton()
                removeButton.setTitle(" Remove ", for: .normal)
                removeButton.showsTouchWhenHighlighted = true
                removeButton.addTarget(self, action: #selector(remove(pressedButton:)), for: .touchUpInside)
                removeButton.setTitleColor(UIColor.black, for: .normal)
                removeButton.backgroundColor = UIColor(displayP3Red: 142/255, green: 139/255, blue: 139/255, alpha: 1)
                removeButton.layer.masksToBounds = true
                removeButton.layer.cornerRadius = 5
                removeButton.layer.borderColor = darkGrey.cgColor
                removeButton.layer.borderWidth = 2
                removeButton.tag = numberOfOurTrades
                //adjust button
                let adjustButton:UIButton = UIButton()
                adjustButton.setTitle(" Adjust ", for: .normal)
                adjustButton.showsTouchWhenHighlighted = true
                adjustButton.addTarget(self, action: #selector(adjust(pressedButton:)), for: .touchUpInside)
                adjustButton.setTitleColor(UIColor.black, for: .normal)
                adjustButton.backgroundColor = UIColor(displayP3Red: 142/255, green: 139/255, blue: 139/255, alpha: 1)
                adjustButton.layer.masksToBounds = true
                adjustButton.layer.cornerRadius = 5
                adjustButton.layer.borderWidth = 2
                adjustButton.layer.borderColor = darkGrey.cgColor
                adjustButton.tag = numberOfOurTrades
                buttonContainer.addArrangedSubview(removeButton)
                buttonContainer.addArrangedSubview(adjustButton)
            }
        }
        else
        {
            yourNameLabel.text = "You"
            theirNameLabel.text = "\(JSONDict["From"] as! String)"
            ourResourceToGive.image = UIImage(named: "resource\(JSONDict["ResourceToSender"] as! String)")
            theirResourceToGive.image = UIImage(named: "resource\(JSONDict["ResourceToReceiver"] as! String)")
            yourAmountLabel.text = "\(JSONDict["AmountToSender"] as! Int) \(JSONDict["ResourceToSender"] as! String)"
            theirAmountLabel.text = "\(JSONDict["AmountToReceiver"] as! Int) \(JSONDict["ResourceToReceiver"] as! String)"
            
            if (dealingWithActiveTrades)
            {
                //accept button
                let acceptButton:UIButton = UIButton()
                acceptButton.setTitle(" Accept ", for: .normal)
                acceptButton.showsTouchWhenHighlighted = true
                acceptButton.addTarget(self, action: #selector(accept(pressedButton:)), for: .touchUpInside)
                acceptButton.setTitleColor(UIColor.black, for: .normal)
                acceptButton.backgroundColor = UIColor(displayP3Red: 142/255, green: 139/255, blue: 139/255, alpha: 1)
                acceptButton.layer.masksToBounds = true
                acceptButton.layer.cornerRadius = 5
                acceptButton.layer.borderColor = darkGrey.cgColor
                acceptButton.layer.borderWidth = 2
                acceptButton.tag = numberOfOurTrades
                //decline button
                let declineButton:UIButton = UIButton()
                declineButton.setTitle(" Decline ", for: .normal)
                declineButton.showsTouchWhenHighlighted = true
                declineButton.addTarget(self, action: #selector(decline(pressedButton:)), for: .touchUpInside)
                declineButton.setTitleColor(UIColor.black, for: .normal)
                declineButton.backgroundColor = UIColor(displayP3Red: 142/255, green: 139/255, blue: 139/255, alpha: 1)
                declineButton.layer.masksToBounds = true
                declineButton.layer.cornerRadius = 5
                declineButton.layer.borderColor = darkGrey.cgColor
                declineButton.layer.borderWidth = 2
                declineButton.tag = numberOfOurTrades
                //adjust button
                let adjustButton:UIButton = UIButton()
                adjustButton.showsTouchWhenHighlighted = true
                adjustButton.setTitle(" Adjust ", for: .normal)
                adjustButton.addTarget(self, action: #selector(adjust(pressedButton:)), for: .touchUpInside)
                adjustButton.setTitleColor(UIColor.black, for: .normal)
                adjustButton.backgroundColor = UIColor(displayP3Red: 142/255, green: 139/255, blue: 139/255, alpha: 1)
                adjustButton.layer.masksToBounds = true
                adjustButton.layer.cornerRadius = 5
                adjustButton.layer.borderColor = darkGrey.cgColor
                adjustButton.layer.borderWidth = 2
                adjustButton.tag = numberOfOurTrades
                //add everthing
                buttonContainer.addArrangedSubview(acceptButton)
                buttonContainer.addArrangedSubview(declineButton)
                buttonContainer.addArrangedSubview(adjustButton)
            }
        }
        
        container.addSubview(nameStackView)
        container.addSubview(amountStackView)
        container.addSubview(imageStackView)
        if (dealingWithActiveTrades)
        {
            container.addSubview(buttonContainer)
        }
        container.isHidden = true
        containersArray.append(container)
        self.view.addSubview(container)
        
    }
    func popluateInOrder(dict:inout [String:[String:Any]], dealingWithActiveTrades:Bool)
    {
        let orderBy:String = dealingWithActiveTrades ? "timeSent" : "timeFinished"
        if dict.count > 0
        {
            var theDictionary:[String:[String:Any]] = dict
            for i in 1...theDictionary.count
            {
                var oldestNumber:Int = 0
                var oldestKey:String = ""
                var jsonDict:[String:Any] = [:]
                for trade in theDictionary
                {
                    jsonDict = trade.value
                    if oldestNumber < jsonDict[orderBy] as! Int
                    {
                        oldestNumber = jsonDict[orderBy] as! Int
                        oldestKey = trade.key
                    }
                }
                if (dealingWithActiveTrades)
                {
                    allTradesKeys.append(oldestKey)
                }
                populateStackView(JSONDict: theDictionary[oldestKey]!, numberOfOurTrades: i, isOurTrade: jsonDict["From"] as! String == UsersInformation.currentUsersUsername ? true : false, dealingWithActiveTrades: dealingWithActiveTrades)
                theDictionary[oldestKey] = nil
            }
        }
    }
    @objc func accept(pressedButton:UIButton)
    {
        applauseSoundPlayer.play()
        let tradeKey = allTradesKeys[pressedButton.tag - 1]
        let JSONDict:[String:Any] = allTrades[tradeKey]!
        var amountOfOurResource:Int = 0
        let currentDate:Int = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
        if UsersInformation.currentUsersActiveResources.contains(JSONDict["ResourceToSender"] as! String)
        {
            amountOfOurResource = Int(Float(currentDate - (UsersInformation.ActivationDate + UsersInformation.currentUsersResources["\(JSONDict["ResourceToSender"] as! String)X"]!)) * UsersInformation.individualResourceMultiplier[JSONDict["ResourceToSender"] as! String]!)
        }
        else
        {
            amountOfOurResource = UsersInformation.currentUsersResources[JSONDict["ResourceToSender"] as! String]!
        }
        if amountOfOurResource >= JSONDict["AmountToSender"] as! Int
        {
            let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
            ref.child("Trades").child(tradeKey).child("Active").setValue(1)
            ref.child("Trades").child(tradeKey).child("timeSent").removeValue()
            ref.child("Trades").child(tradeKey).child("timeFinished").setValue(currentDate)
            ref.child("NamesOfUsers").child(JSONDict["From"] as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                let TheirResources: [String:Int] = snapshot.value as! [String:Int]
                var TheirResourceActive:Bool = false
                if let _ = TheirResources["\(JSONDict["ResourceToReceiver"] as! String)X"]
                {
                    TheirResourceActive = true
                }
                //change our resources.
                if UsersInformation.currentUsersActiveResources.contains(JSONDict["ResourceToSender"] as! String)
                {
                    self.changeOurResources(X: "X", upOrDown: 1, JSONDict: JSONDict, TheirResourceIsActive: TheirResourceActive)
                }
                else
                {
                    self.changeOurResources(X: "", upOrDown: -1, JSONDict: JSONDict, TheirResourceIsActive: TheirResourceActive)
                }
                //change their resources
                self.changeTheirResources(JSONDict: JSONDict, PartnersResources: TheirResources)
                //reset stack view
                self.allTrades = [:]
                self.finishedTrades = [:]
                self.allTradesKeys = []
                self.deleteContainers()
                self.ButtonInView = 1
                self.containersArray = []
                self.discoverTrades(populatingActiveTrades: true)
            })
            
        }
        else
        {
            let alert = UIAlertController(title: "Not enough \(JSONDict["ResourceToSender"] as! String)!", message: "You don't have enough \(JSONDict["ResourceToSender"] as! String) to complete this trade, try adjusting the amounts.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction) in
                alert.dismiss(animated: true, completion: nil)
            }) )
            self.present(alert, animated: true, completion: nil)
        }
    }
    @objc func decline(pressedButton:UIButton) //decline means you recieved the offer
    {
        buttonSoundPlayer.play()
        let tradeKey = allTradesKeys[pressedButton.tag - 1]
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
        //give back their Resources from the pot.
        let JSONDict:[String:Any] = allTrades[tradeKey]!
        ref.child("NamesOfUsers").child(JSONDict["From"] as! String).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists()
            {
                let allHisResources = snapshot.value as! [String:Int]
                var newValue:Int = 0
                var realResource:String = ""
                var achieved:Bool = false
                for resources in allHisResources
                {
                    if resources.key == JSONDict["ResourceToReceiver"] as! String
                    {
                        achieved = true
                        realResource = JSONDict["ResourceToReceiver"] as! String
                        newValue = resources.value + Int(JSONDict["AmountToReceiver"] as! Int)
                    }
                    else if resources.key == "\(JSONDict["ResourceToReceiver"] as! String)X"
                    {
                        achieved = true
                        realResource = "\(JSONDict["ResourceToReceiver"] as! String)X"
                        newValue = resources.value - Int(JSONDict["AmountToReceiver"] as! Int)
                    }
                }
                if achieved
                {
                    ref.child("NamesOfUsers").child(JSONDict["From"] as! String).child(realResource).setValue(newValue)
                }
                else //they no longer have any of this resource. and there is no way this resource is an active resource, otherwise it would have a value so no need to check for "X".
                {
                    ref.child("NamesOfUsers").child(JSONDict["From"] as! String).child(JSONDict["ResourceToReceiver"] as! String).setValue(JSONDict["AmountToReceiver"] as! Int)
                }
                
            }
            
            //decline the trade, remove it.
            let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
            ref.child("Trades").child(tradeKey).child("Active").setValue(2)
            ref.child("Trades").child(tradeKey).child("timeSent").removeValue()
            ref.child("Trades").child(tradeKey).child("timeFinished").setValue(currentDate)
            self.allTrades = [:]
            self.finishedTrades = [:]
            self.allTradesKeys = []
            self.deleteContainers()
            self.ButtonInView = 1
            self.containersArray = []
        })
        createActivityIndicator()
        discoverTrades(populatingActiveTrades: true)
    }
    @objc func adjust(pressedButton:UIButton)
    {
        buttonSoundPlayer.play()
        let tradeKey = allTradesKeys[pressedButton.tag - 1]
        UsersInformation.adjustTrade[tradeKey] = allTrades[tradeKey]
        let JSONDict:[String:Any] = allTrades[tradeKey]!
        if JSONDict["From"] as! String  == UsersInformation.currentUsersUsername
        {
            UsersInformation.userWeAreTradingWith = JSONDict["To"] as! String
        }
        else
        {
            UsersInformation.userWeAreTradingWith = JSONDict["From"] as! String
        }
        let ourActivityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
        ourActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        ourActivityIndicator.hidesWhenStopped = true
        //ourActivityIndicator.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/3, height: self.view.frame.width/3)
        ourActivityIndicator.center = self.view.center
        self.view.addSubview(ourActivityIndicator)
        ourActivityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        Database.database().reference(withPath: UsersInformation.classWeAreIn).child("NamesOfUsers").child(UsersInformation.userWeAreTradingWith).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists()
            {
                ourActivityIndicator.stopAnimating()
                UIApplication.shared.endIgnoringInteractionEvents()
                UsersInformation.clickedUsersActiveResources = []
                UsersInformation.clickedUsersResources = snapshot.value as! [String: Int]
                UsersInformation.clickedUsersResources["Wealth"] = nil
                for item in UsersInformation.clickedUsersResources
                {
                    if item.key.last == "X"
                    {
                        UsersInformation.clickedUsersResources[item.key] = nil
                        UsersInformation.clickedUsersResources[String(item.key.dropLast())] = item.value
                        UsersInformation.clickedUsersActiveResources.append(String(item.key.dropLast()))
                    }
                }
                self.performSegue(withIdentifier: "toMakeATrade", sender: nil)
            }
            ourActivityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
        })
    }
    func changeTheirResources(JSONDict: [String:Any], PartnersResources: [String:Int])
    {
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
        //add the resource they will get
        if JSONDict["AmountToSender"] as! Int != 0
        {
            var valueToAdd:Int = 0
            //check if they already have any of the resource we are giving them.
            if PartnersResources[JSONDict["ResourceToSender"] as! String] != nil || PartnersResources["\(JSONDict["ResourceToSender"] as! String)X"] != nil //they have this resource...
            {
                if PartnersResources[JSONDict["ResourceToSender"] as! String] != nil // resource is not one of their Active resources
                {
                    valueToAdd = PartnersResources[JSONDict["ResourceToSender"] as! String]!
                    valueToAdd += JSONDict["AmountToSender"] as! Int
                    ref.child("NamesOfUsers").child(JSONDict["From"] as! String).child(JSONDict["ResourceToSender"] as! String).setValue(valueToAdd)
                }
                else // resource is one of their active resources
                {
                    valueToAdd = PartnersResources["\(JSONDict["ResourceToSender"] as! String)X"]!
                    valueToAdd -= JSONDict["AmountToSender"] as! Int
                    ref.child("NamesOfUsers").child(JSONDict["From"] as! String).child("\(JSONDict["ResourceToSender"] as! String)X").setValue(valueToAdd)
                }
            }
            else //they don't have this resource....
            {
                valueToAdd = JSONDict["AmountToSender"] as! Int
                ref.child("NamesOfUsers").child(JSONDict["From"] as! String).child(JSONDict["ResourceToSender"] as! String).setValue(valueToAdd)
            }
        }
    }
    func changeOurResources(X:String, upOrDown:Int, JSONDict:[String:Any], TheirResourceIsActive:Bool)
    {
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
    //subtract our resource
        if JSONDict["AmountToSender"] as! Int != 0
        {
            var valueToChange:Int = UsersInformation.currentUsersResources["\(JSONDict["ResourceToSender"] as! String)\(X)"]!
            valueToChange += (JSONDict["AmountToSender"] as! Int * upOrDown)
            ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child("\(JSONDict["ResourceToSender"] as! String)\(X)").setValue(valueToChange)
            UsersInformation.currentUsersResources["\(JSONDict["ResourceToSender"] as! String)\(X)"] = valueToChange
            if X == "" && valueToChange == 0
            {
                ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child("\(JSONDict["ResourceToSender"] as! String)").removeValue()
                UsersInformation.currentUsersResources.removeValue(forKey: JSONDict["ResourceToSender"] as! String)
            }
        }
        if JSONDict["AmountToReceiver"] as! Int != 0
        {
            //add our resource
            var valueToAdd:Int = 0
            var XorNo:String = ""
            if UsersInformation.currentUsersResources["\(JSONDict["ResourceToReceiver"] as! String)X"] != nil //This is one of our Active resources
            {
                valueToAdd = UsersInformation.currentUsersResources["\(JSONDict["ResourceToReceiver"] as! String)X"]! - Int(JSONDict["AmountToReceiver"] as! Int)
                XorNo = "X"
            }
            else if UsersInformation.currentUsersResources[JSONDict["ResourceToReceiver"] as! String] != nil // check if we already have this resource
            {
                valueToAdd = UsersInformation.currentUsersResources[JSONDict["ResourceToReceiver"] as! String]!
                valueToAdd += JSONDict["AmountToReceiver"] as! Int
            }
            else
            {
                valueToAdd = JSONDict["AmountToReceiver"] as! Int
            }
            ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child("\(JSONDict["ResourceToReceiver"] as! String)\(XorNo)").setValue(valueToAdd)
            UsersInformation.currentUsersResources["\(JSONDict["ResourceToReceiver"] as! String)\(XorNo)"] = valueToAdd
        }
    }
    
    @objc func remove(pressedButton:UIButton)
    {
        //removes only show up on trades you sent to them....
        buttonSoundPlayer.play()
        let tradeKey = allTradesKeys[pressedButton.tag - 1]
        //give back resources in pot.
        let JSONDict:[String:Any] = allTrades[tradeKey]!
        var message = ""
        var realResource:String = ""
        if JSONDict["From"] as! String == UsersInformation.currentUsersUsername
        {
            message = "ToReceiver"
        }
        else
        {
            message = "ToSender"
        }
        if UsersInformation.currentUsersActiveResources.contains(JSONDict["Resource\(message)"] as! String)
        {
            realResource = "\(JSONDict["Resource\(message)"] as! String)X"
            let newValue:Int = UsersInformation.currentUsersResources["\(JSONDict["Resource\(message)"] as! String)X"]! - Int(JSONDict["Amount\(message)"] as! Int)
            UsersInformation.currentUsersResources["\(JSONDict["Resource\(message)"] as! String)X"] = newValue
        }
        else
        {
            realResource = JSONDict["Resource\(message)"] as! String
            if UsersInformation.currentUsersResources[JSONDict["Resource\(message)"] as! String] != nil
            {
                let newValue:Int = UsersInformation.currentUsersResources[JSONDict["Resource\(message)"] as! String]! + Int(JSONDict["Amount\(message)"] as! Int)
                UsersInformation.currentUsersResources[JSONDict["Resource\(message)"] as! String] = newValue
            }
            else
            {
                        UsersInformation.currentUsersResources[JSONDict["Resource\(message)"] as! String] = Int(JSONDict["Amount\(message)"] as! Int)
            }
        }
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
        ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child(realResource).setValue(UsersInformation.currentUsersResources[realResource])
        //remove Trade
        ref.child("Trades").child(tradeKey).removeValue()
        allTrades = [:]
        finishedTrades = [:]
        allTradesKeys = []
        deleteContainers()
        ButtonInView = 1
        containersArray = []
        createActivityIndicator()
        discoverTrades(populatingActiveTrades: true)
    }
    func HideAppropriateViews()
    {
        //at all times, the top most visible container's tag is equal to buttonInView
        for nextView in containersArray
        {
            if nextView.tag == ButtonInView || nextView.tag == ButtonInView + 1
            {
                nextView.isHidden = false
            }
            else
            {
                nextView.isHidden = true
            }
        }
        
    }
    
    @IBAction func upArrowWasTouched(_ sender: Any) {
        upArrow.isEnabled = false
        downArrow.isEnabled = false
        moveViews(MoveUp: true)
        ButtonInView = ButtonInView - 1
    }
    func moveViews(MoveUp:Bool)
    {
        var tagToFadeOut = 0
        var tagToFadeIn = 0
        var upOrDownOperator:CGFloat = 1
        if MoveUp
        {
            upOrDownOperator = -1
            tagToFadeIn = -1
            tagToFadeOut = 1
        }
        else
        {
            tagToFadeOut = 0
            tagToFadeIn = 2
        }
        for containerX in containersArray
        {
            if containerX.tag == ButtonInView + tagToFadeOut
            {
                UIView.animate(withDuration: 0.5, animations: {
                    containerX.center = CGPoint(x: self.view.frame.midX, y: containerX.center.y - ((containerX.frame.height + self.paddingSpace * 2) * upOrDownOperator))
                    containerX.alpha = 0
                }, completion: { (true) in
                    containerX.isHidden = true
                    containerX.alpha = 1
                    // we need to determine which buttons are needed, so lets do that once, after this view animates.
                    self.whichButtonsAreNeeded()
                    //up and down arrows are not enabled, lets reset that once, in this function
                    self.upArrow.isEnabled = true
                    self.downArrow.isEnabled = true
                })
            }
            else if containerX.tag == ButtonInView + tagToFadeIn
            {
                containerX.alpha = 0
                containerX.isHidden = false
                UIView.animate(withDuration: 0.5, animations: {
                    containerX.center = CGPoint(x: self.view.frame.midX, y: containerX.center.y - ((containerX.frame.height + self.paddingSpace * 2) * upOrDownOperator))
                    containerX.alpha = 1
                })
            }
            else
            {
                UIView.animate(withDuration: 0.5, animations: {
                    containerX.center = CGPoint(x: self.view.frame.midX, y: containerX.center.y - ((containerX.frame.height + self.paddingSpace * 2) * upOrDownOperator))
                })
            }
        }
    }
    
    @IBAction func downArrowWasTouched(_ sender: Any) {
        upArrow.isEnabled = false
        downArrow.isEnabled = false
        moveViews(MoveUp: false)
        ButtonInView = ButtonInView + 1
    }
    
    func whichButtonsAreNeeded()
    {
        if containersArray.count < 3
        {
            upArrow.isHidden = true
            downArrow.isHidden = true
        }
        else
        {
            if ButtonInView == 1
            {
                upArrow.isHidden = true
                downArrow.isHidden = false
            }
            else if ButtonInView == containersArray.count - 1
            {
                upArrow.isHidden = false
                downArrow.isHidden = true
            }
            else
            {
                upArrow.isHidden = false
                downArrow.isHidden = false
            }

        }
    }
    func deleteContainers()
    {
        for subviewX in containersArray
        {
            if subviewX.tag != 0
            {
                subviewX.removeFromSuperview()
            }
        }
    }

    @IBAction func backButtonWasPressed(_ sender: Any) {
        backTickSoundPlayer.play()
        self.performSegue(withIdentifier: "backToTrades", sender: nil)
    }
    @IBAction func activeStatusWasToggled(_ sender: Any) {
        deleteContainers()
        allTrades = [:]
        finishedTrades = [:]
        allTradesKeys = []
        containersArray = []
        ButtonInView = 1
        createActivityIndicator()
        if (activitySelector.selectedSegmentIndex == 0)
        {
            titleLabel.text = "Active Trades"
            noActivesLabel.text = "You currently do not have any active trades"
            noActivesLabel.isHidden = true
            discoverTrades(populatingActiveTrades: true)
        }
        else
        {
            titleLabel.text = "Finished Trades"
            noActivesLabel.text = "You currently do not have any finished trades"
            noActivesLabel.isHidden = true
            discoverTrades(populatingActiveTrades: false)
        }
    }
    func checkIfWeHaveTrades()
    {
        if containersArray.count == 0
        {
            noActivesLabel.isHidden = false
        }
        else
        {
            noActivesLabel.isHidden = true
        }
    }
    @IBOutlet var activitySelector: UISegmentedControl!
    @IBOutlet var noActivesLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var upArrow: UIButton!
    @IBOutlet var downArrow: UIButton!
    
}
