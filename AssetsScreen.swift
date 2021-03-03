//
//  AssetsScreen.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 5/10/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class assetsScreen:UIViewController {
    
    var preventativeTimer:Timer = Timer()
    var backgroundLabel:UILabel = UILabel()
    var wealthLabel:UILabel = UILabel()
    var removeWealthTimer:Timer = Timer()
    var wealthIsShowing:Bool = Bool()
    var boxIsActive:Bool = false
    var amountSpent:Int = 0
    var trackBoughtThings: [String : Int] = [:]
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var buildSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var denySoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        let buttonClickPath = Bundle.main.path(forResource: "buttonClick.mp3", ofType: nil)!
        let buttonClickSound = NSURL(fileURLWithPath: buttonClickPath)
        let buildPath = Bundle.main.path(forResource: "Money.mp3", ofType: nil)!
        let buildSound = NSURL(fileURLWithPath: buildPath)
        let denyPath = Bundle.main.path(forResource: "deny.mp3", ofType: nil)!
        let denySound = NSURL(fileURLWithPath: denyPath)
        do {
            try buttonSoundPlayer = AVAudioPlayer(contentsOf: buttonClickSound as URL)
            buttonSoundPlayer.prepareToPlay()
        } catch {
            print("Bummer....")
        }
        do {
            try buildSoundPlayer = AVAudioPlayer(contentsOf: buildSound as URL)
            buildSoundPlayer.prepareToPlay()
        } catch {
            print("Bummer....")
        }
        do {
            try denySoundPlayer = AVAudioPlayer(contentsOf: denySound as URL)
        } catch {
            print("What a shame...")
        }
        let backTickPath = Bundle.main.path(forResource: "backTick.mp3", ofType: nil)!
        let backTickSound = NSURL(fileURLWithPath: backTickPath)
        do {
            try backTickSoundPlayer = AVAudioPlayer(contentsOf: backTickSound as URL)
            backTickSoundPlayer.prepareToPlay()
        } catch {
        }
        NoteLabel.frame = CGRect(x:Int(NoteLabel.frame.origin.x), y: Int(NoteLabel.frame.origin.y), width: Int(NoteLabel.frame.width), height: Int(NoteLabel.frame.height))
        setup()
        createMoneyThingy()
        
    }
    func setup()
    {
        let allResources: [String] = ["Wheat","Lumber","Iron","Stone","Rope","Glass", "Wool","Oil","Rubber","Spices","Sugar", "Brick"]
        var price:Int = 0
        var priceAsString:String = ""
        for i in 0...allResources.count - 1
        {
            if UsersInformation.currentUsersActiveResources.contains(allResources[i])
            {
                price = determinePrice(possiblePrices: 30000, tag: i)
                priceAsString = "\(String(price.description.dropLast(3))),000"
                createNextAsset( labelText: "  Produce \(allResources[i]) faster by 5%: $\(priceAsString).", i: i)
            }
            else
            {
                price = determinePrice(possiblePrices: 40000, tag: i)
                priceAsString = "\(String(price.description.dropLast(3))),000"
                createNextAsset(labelText: "  Begin producing \(allResources[i]), Cost: $\(priceAsString)", i: i)
            }
        }
    }
    func createNextAsset(labelText:String, i:Int)
    {
        let nextStackView:UIStackView = UIStackView()
        nextStackView.alignment = .fill
        nextStackView.distribution = .fillProportionally
        nextStackView.axis = .horizontal
        nextStackView.tag = i + 1
        //label
        let nextLabel = UILabel()
        nextLabel.text = labelText
        let backgroundColorft = UIColor(displayP3Red: 142/255, green: 139/255, blue: 139/255, alpha: 1)
        nextLabel.backgroundColor = backgroundColorft
        nextLabel.layer.masksToBounds = true
        nextLabel.layer.cornerRadius = 5
        let darkGrey = UIColor(displayP3Red: 35/255, green: 31/255, blue: 32/255, alpha: 1)
        nextLabel.layer.borderColor = darkGrey.cgColor
        nextLabel.textAlignment = .justified
        nextLabel.adjustsFontSizeToFitWidth = true
        nextLabel.tag = i + 1
        nextStackView.addArrangedSubview(nextLabel)
        //button
        let nextButton = UIButton()
        nextButton.setTitle("Buy", for: .normal)
        nextButton.setTitleColor(UIColor.black, for: .normal)
        nextButton.backgroundColor = backgroundColorft
        nextButton.layer.masksToBounds = true
        nextButton.layer.cornerRadius = 5
        nextButton.layer.borderWidth = 2
        nextButton.layer.borderColor = darkGrey.cgColor
        nextButton.frame = CGRect(x: 0, y: 0, width: 0, height: 30)
        nextButton.tag = i + 1
        nextButton.widthAnchor.constraint(equalToConstant: self.view.frame.width/6).isActive = true
        nextButton.addTarget(self, action: #selector(buyButtonWasPressed(pressedButton:)), for: .touchUpInside)
        if !UsersInformation.classIsActive
        {
            nextButton.isEnabled = false
        }
        nextStackView.addArrangedSubview(nextButton)
        textStackView.addArrangedSubview(nextStackView)
    }
    
    @objc func buyButtonWasPressed(pressedButton: UIButton)
    {
        let allResources: [String] = ["Wheat","Lumber","Iron","Stone","Rope","Glass", "Wool","Oil","Rubber","Spices","Sugar", "Brick"]
        var price:Int = 0
        let boughtResource = allResources[pressedButton.tag - 1]
        if UsersInformation.currentUsersActiveResources.contains(boughtResource) // upgrade this resource
        {
            price = determinePrice(possiblePrices: 30000, tag: pressedButton.tag - 1)
            if UsersInformation.wealthOfCurrentUser >= price
            {
                buildSoundPlayer.play()
                UsersInformation.wealthOfCurrentUser -= price
                let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
                let currentValueOfResource = Int(Float(currentDate - (UsersInformation.ActivationDate + UsersInformation.currentUsersResources["\(boughtResource)X"]!)) * UsersInformation.individualResourceMultiplier[boughtResource]!)
                UsersInformation.individualResourceMultiplier[boughtResource]! += UsersInformation.multiplier * 0.05
                let step1:Double = Double(currentValueOfResource) / Double(UsersInformation.individualResourceMultiplier[boughtResource]!)
                let step2:Double = Double(currentDate) - step1
                let newValueOfResource = Int(step2 - Double(UsersInformation.ActivationDate))
                UsersInformation.currentUsersResources["\(boughtResource)X"] = newValueOfResource
                print("Current Value Of resource: \(currentValueOfResource) and the new value is \(newValueOfResource)")
                if trackBoughtThings[boughtResource] == nil
                {
                    trackBoughtThings[boughtResource] = 1
                    amountSpent = price
                }
                else
                {
                    trackBoughtThings[boughtResource]! += 1
                    amountSpent += price
                }
                animateTheWealthButton(amount: price)
                doAllPreventativeSavingStuff()
            }
            else
            {
                denySoundPlayer.play()
                visuallyDeny(Distance: 20, button: pressedButton)
            }
        }
        else //begin producing new resource
        {
            price = determinePrice(possiblePrices: 40000, tag: pressedButton.tag - 1)
            if UsersInformation.wealthOfCurrentUser >= price
            {
                buildSoundPlayer.play()
                UsersInformation.wealthOfCurrentUser -= price
                UsersInformation.currentUsersActiveResources.append(boughtResource)
                let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
                let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
                var valueOfResource = 0
                let multiplier = UsersInformation.multiplier/2
                if UsersInformation.currentUsersResources[boughtResource] != nil
                {
                    let Step1:Double = Double(UsersInformation.currentUsersResources[boughtResource]!)/Double(multiplier)
                    let Step2 = Double(currentDate) - Step1
                    valueOfResource = Int(Step2 - Double(UsersInformation.ActivationDate))
                    UsersInformation.currentUsersResources[boughtResource] = nil
                    ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child(boughtResource).removeValue()
                }
                else
                {
                    valueOfResource = currentDate - UsersInformation.ActivationDate
                }
                UsersInformation.currentUsersResources["\(boughtResource)X"] = valueOfResource
                UsersInformation.individualResourceMultiplier[boughtResource] = multiplier
                ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child("\(boughtResource)X").setValue(valueOfResource)
                ref.child("UsersMultipliers").child(UsersInformation.currentUsersUsername).child("\(boughtResource)").setValue(multiplier)
                print("Users multipliers at position \(boughtResource) was just set to \(multiplier)")
                ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child("Wealth").setValue(UsersInformation.wealthOfCurrentUser)
                var JSONDict:[String: Any] = [:]
                JSONDict["Creator"] = UsersInformation.currentUsersUsername
                JSONDict["NewResource"] = boughtResource
                JSONDict["AmountSpent"] = price
                ref.child("BoughtThings").childByAutoId().setValue(JSONDict)
                //and somewhere else, save start date and multiplier
                for object in textStackView.subviews
                {
                    print(object)
                    if object.tag != 0
                    {
                        object.removeFromSuperview()
                    }
                }
                animateTheWealthButton(amount: price)
                setup()
            }
            else
            {
                denySoundPlayer.play()
                visuallyDeny(Distance: 20, button: pressedButton)
            }
        }
        print("Resource: \(boughtResource), and price: \(price)")
    }
    func doAllPreventativeSavingStuff()
    {
        if preventativeTimer.isValid
        {
            preventativeTimer.invalidate()
        }
        preventativeTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(preventSavingToMuch), userInfo: nil, repeats: false)
    }
    
    @objc func preventSavingToMuch()
    {
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
        ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child("Wealth").setValue(UsersInformation.wealthOfCurrentUser)
        ref.child("UsersMultipliers").child(UsersInformation.currentUsersUsername).setValue(UsersInformation.individualResourceMultiplier)
        print("UsersMultipliers was just set to \(UsersInformation.individualResourceMultiplier)")
        for thing in trackBoughtThings
        {
            var JSONDict: [String: Any] = [:]
            let resourceUpgraded:String = String(thing.key)
            JSONDict["Creator"] = UsersInformation.currentUsersUsername
            JSONDict["Upgraded"] = resourceUpgraded
            JSONDict["NumberOfTimesUpgraded"] = thing.value
            JSONDict["AmountSpent"] = amountSpent
            ref.child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child("\(resourceUpgraded)X").setValue(UsersInformation.currentUsersResources["\(resourceUpgraded)X"])
            ref.child("BoughtThings").childByAutoId().setValue(JSONDict)
        }
        trackBoughtThings = [:]
    }
    @IBAction func questionButtonWasPushed(_ sender: Any) {
        buttonSoundPlayer.play()
        boxIsActive = true
        let boxThing:UIImageView = UIImageView()
        boxThing.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/2, height: self.view.frame.height/3)
        boxThing.center = CGPoint(x: self.view.frame.width - boxThing.frame.width/2 - 14, y: boxThing.frame.height/2 + 20)
        boxThing.tag = 921
        let boxThingImage = UIImage(named: "greyBox")
        boxThing.image = boxThingImage
        //initialize label
        let InformativeLabel:UILabel = UILabel()
        InformativeLabel.adjustsFontSizeToFitWidth = true
        InformativeLabel.textAlignment = .center
        InformativeLabel.numberOfLines = 0
        InformativeLabel.frame = CGRect(x: boxThing.frame.minX + 5, y: boxThing.frame.minY + 10, width: boxThing.frame.width - 10, height: boxThing.frame.height - 20)
        InformativeLabel.tag = 922
        InformativeLabel.text = "Your country is better at producing your main resources, producing other resources is more difficult and thus takes twice as long! However, you can always upgrade your production of any resource."
        self.view.addSubview(boxThing)
        self.view.addSubview(InformativeLabel)
        
        
    }
    func createMoneyThingy()
    {
        let itemHeight = self.view.frame.height/12
        backgroundLabel.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/3, height: itemHeight)
        backgroundLabel.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY - itemHeight)
        backgroundLabel.backgroundColor = UIColor.lightGray
        backgroundLabel.text = ""
        backgroundLabel.layer.masksToBounds = true
        backgroundLabel.layer.cornerRadius = 5
        backgroundLabel.layer.borderWidth = 2
        backgroundLabel.layer.borderColor = UIColor.black.cgColor
        wealthLabel.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/3 - 6, height: itemHeight)
        wealthLabel.center = backgroundLabel.center
        wealthLabel.textAlignment = .center
        wealthLabel.adjustsFontSizeToFitWidth = true
        wealthLabel.text = "Wealth: $\(UsersInformation.wealthOfCurrentUser)"
        self.view.addSubview(backgroundLabel)
        self.view.addSubview(wealthLabel)
    }
    func animateTheWealthButton(amount:Int)
    {
        if removeWealthTimer.isValid
        {
            removeWealthTimer.invalidate()
        }
        removeWealthTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (Timer) in
            let itemHeight = self.view.frame.height/12
            UIView.animate(withDuration: 0.3, animations: {
                self.backgroundLabel.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY - itemHeight)
                self.wealthLabel.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY - itemHeight)
            }, completion: { (true) in
                self.wealthIsShowing = false
            })
        })
        if wealthIsShowing == false
        {
            wealthIsShowing = true
            UIView.animate(withDuration: 0.3, animations: {
                let itemHeight = self.view.frame.height/12
                self.backgroundLabel.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + itemHeight)
                self.wealthLabel.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + itemHeight)
            }) { (true) in
                self.makePrettyLittleAnimation(amount: amount)
            }
        }
        else
        {
            makePrettyLittleAnimation(amount: amount)
        }
    }
    func makePrettyLittleAnimation(amount:Int)
    {
        let fakeAmount:UILabel = UILabel()
        fakeAmount.frame = self.wealthLabel.frame
        fakeAmount.textAlignment = .center
        fakeAmount.textColor = UIColor.red
        fakeAmount.adjustsFontSizeToFitWidth = true
        fakeAmount.font = UIFont.boldSystemFont(ofSize: 17.0)
        fakeAmount.text = "+ $\(amount)"
        wealthLabel.text = "Wealth: $\(UsersInformation.wealthOfCurrentUser)"
        self.view.addSubview(fakeAmount)
        UIView.animate(withDuration: 1, animations: {
            fakeAmount.alpha = 0
            fakeAmount.center = CGPoint(x: self.view.frame.midX, y: self.wealthLabel.frame.midY + 60)
        }) { (true) in
            fakeAmount.removeFromSuperview()
        }
    }
    func determinePrice(possiblePrices:Int, tag:Int) -> Int
    {
        var price:Int = 0;
        if tag <= 1
        {
            price = possiblePrices
        }
        else
        {
            price = (possiblePrices - 5000)
        }
        return price
    }
    func visuallyDeny(Distance:CGFloat, button:UIButton)
    {
        if (Distance > 0)
        {
            let duration:Double = 0.1
            UIView.animate(withDuration: duration, animations: {
                button.center = CGPoint(x: button.center.x - Distance , y: button.center.y)
            }) { (true) in
                UIView.animate(withDuration: duration * 2, animations: {
                    button.center = CGPoint(x: button.center.x + Distance * 2, y: button.center.y)
                }) { (true) in
                    UIView.animate(withDuration: duration, animations: {
                        button.center = CGPoint(x: button.center.x - Distance, y: button.center.y)
                    }) { (true) in
                        self.visuallyDeny(Distance: Distance - 15, button: button)
                    }
                }
            }
        }
    }
    @IBAction func backButtonWasTouched(_ sender: Any) {
        backTickSoundPlayer.play()
        self.performSegue(withIdentifier: "backToBuild", sender: nil)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (boxIsActive)
        {
            let image:UIImageView = self.view.viewWithTag(921) as! UIImageView
            image.removeFromSuperview()
            let label:UILabel = self.view.viewWithTag(922) as! UILabel
            label.removeFromSuperview()
            boxIsActive = false
        }
    }
    
    @IBOutlet var questionButton: UIButton!
    @IBOutlet var textStackView: UIStackView!
    @IBOutlet var NoteLabel: UILabel!
}
