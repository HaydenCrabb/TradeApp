//
//  buildScreen.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 4/6/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class buildingScreen : UIViewController
{
    var valueOfPushed:Int = 0
    var alreadyPushed:Bool = false
    var informationIsNeeded = false
    var trackBoughtThings: [String:Int] = ["Car": 0, "House": 0, "Boat": 0, "Bread": 0, "Candy": 0]
    var preventativeTimer:Timer = Timer()
    let RequirementsLabel:UILabel = UILabel()
    let ProfitLabel:UILabel = UILabel()
    let BuildButton:UIButton = UIButton()
    let BuildBackGround:UILabel = UILabel()
    var removeWealthTimer:Timer = Timer()
    let backgroundLabel = UILabel()
    let wealthLabel = UILabel()
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var denySoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var buildSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var slideSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var wealthIsShowing:Bool = false
    
    override func viewDidLoad() {
        let buttonClickPath = Bundle.main.path(forResource: "buttonClick.mp3", ofType: nil)!
        let buttonClickSound = NSURL(fileURLWithPath: buttonClickPath)
        let denyPath = Bundle.main.path(forResource: "deny.mp3", ofType: nil)!
        let denySound = NSURL(fileURLWithPath: denyPath)
        let buildPath = Bundle.main.path(forResource: "Money.mp3", ofType: nil)!
        let buildSound = NSURL(fileURLWithPath: buildPath)
        let slidePath = Bundle.main.path(forResource: "slide.mp3", ofType: nil)!
        let slideSound = NSURL(fileURLWithPath: slidePath)
        do {
            try buttonSoundPlayer = AVAudioPlayer(contentsOf: buttonClickSound as URL)
            buttonSoundPlayer.prepareToPlay()
        } catch {
            print("Bummer....")
        }
        do {
            try denySoundPlayer = AVAudioPlayer(contentsOf: denySound as URL)
            denySoundPlayer.prepareToPlay()
        } catch {
            print("That's a shame.")
        }
        do {
            try buildSoundPlayer = AVAudioPlayer(contentsOf: buildSound as URL)
            buildSoundPlayer.prepareToPlay()
        } catch {
            print("To bad for you....")
        }
        do {
            try slideSoundPlayer = AVAudioPlayer(contentsOf: slideSound as URL)
            slideSoundPlayer.prepareToPlay()
        } catch {
            print("To bad for you....")
        }
        let backTickPath = Bundle.main.path(forResource: "backTick.mp3", ofType: nil)!
        let backTickSound = NSURL(fileURLWithPath: backTickPath)
        do {
            try backTickSoundPlayer = AVAudioPlayer(contentsOf: backTickSound as URL)
            backTickSoundPlayer.prepareToPlay()
        } catch {
        }
        manipulateTheOutlets(myBool: false)
        //initialize the requirements label
            RequirementsLabel.isHidden = true
            RequirementsLabel.textAlignment = .center
            RequirementsLabel.textColor = UIColor.black
            RequirementsLabel.adjustsFontSizeToFitWidth = true
        //initialize the profit label
            ProfitLabel.isHidden = true
            ProfitLabel.textAlignment = .center
            ProfitLabel.textColor = UIColor.black
            ProfitLabel.adjustsFontSizeToFitWidth = true
        //initialize the build button
            BuildButton.isHidden = true
            BuildButton.showsTouchWhenHighlighted = true
            BuildButton.setTitleColor(UIColor.black, for: UIControlState.normal)
            BuildButton.addTarget(self, action: #selector(buildWhateverProduct), for: UIControlEvents.touchUpInside)
        //initialize the build background
            BuildBackGround.isHidden = true
            BuildBackGround.layer.masksToBounds = true
            BuildBackGround.layer.cornerRadius = 5
            BuildBackGround.layer.borderWidth = 2
            let darkGrey = UIColor(displayP3Red: 35/255, green: 31/255, blue: 32/255, alpha: 1)
            BuildBackGround.layer.borderColor = darkGrey.cgColor
            BuildBackGround.backgroundColor = UIColor(displayP3Red: 142/255, green: 139/255, blue: 139/255, alpha: 1)
            let distanceApart = self.view.frame.height/6
            carProduct.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + (distanceApart * 1))
            houseProduct.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + (distanceApart * 2))
            boatProduct.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + (distanceApart * 3))
            breadProduct.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + (distanceApart * 4))
            candyProduct.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.minY + (distanceApart * 5))
        //add views.
        view.addSubview(RequirementsLabel)
        view.addSubview(ProfitLabel)
        view.addSubview(BuildBackGround)
        view.addSubview(BuildButton)
        createWealthLabel()
        if (UsersInformation.settings["NoAssets"]!)
        {
            assetsButton.isHidden = true
            assetsInfoLabel.isHidden = true
            assetsButtonLabel.isHidden = true
        }
    }
    func createWealthLabel()
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
    func manipulateTheOutlets(myBool:Bool)
    {
        //all the outlets that should appear first (The overview area)
        productsButton.isHidden = myBool
        productsButtonLabel.isHidden = myBool
        productsInfoLabel.isHidden = myBool
        if (UsersInformation.settings["NoAssets"] == false)
        {
            assetsButton.isHidden = myBool
            assetsButtonLabel.isHidden = myBool
            assetsInfoLabel.isHidden = myBool
        }
        carProduct.isHidden = !myBool
        houseProduct.isHidden = !myBool
        boatProduct.isHidden = !myBool
        breadProduct.isHidden = !myBool
        candyProduct.isHidden = !myBool
    }
    
    @IBAction func backButtonWasTouched(_ sender: Any) {
        backTickSoundPlayer.play()
        if productsButton.isHidden == false
        {
            self.performSegue(withIdentifier: "buildBackToOverview", sender: nil)
        }
        else if carProduct.isHidden == false //viewing products
        {
            deleteInformation()
            manipulateTheOutlets(myBool: false)
        }
    }
    @objc func buildWhateverProduct()
    {
        if UsersInformation.classIsActive
        {
            let allResources: [String] = ["Lumber", "Iron", "Stone", "Rope", "Wheat", "Glass", "Spices", "Oil", "Brick", "Wool", "Sugar", "Rubber"]
            var PossibleValuesOfActiveResources: [String : Int] = ["Lumber": 0, "Stone": 0, "Rope": 0, "Iron": 0, "Wheat": 0, "Glass": 0, "Spices": 0, "Rubber": 0, "Wool": 0, "Sugar": 0, "Brick": 0, "Oil": 0,]
            for i in 0...allResources.count - 1
            {
                if UsersInformation.currentUsersResources[allResources[i]] != nil
                {
                    PossibleValuesOfActiveResources[allResources[i]] = UsersInformation.currentUsersResources[allResources[i]]
                }
            }
            for i in 0...UsersInformation.currentUsersActiveResources.count - 1
            {
                let holderVar:Int = UsersInformation.currentUsersResources["\(UsersInformation.currentUsersActiveResources[i])X"]!
                let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
                PossibleValuesOfActiveResources[UsersInformation.currentUsersActiveResources[i]] = Int(Float(currentDate - (UsersInformation.ActivationDate + holderVar)) * UsersInformation.individualResourceMultiplier[UsersInformation.currentUsersActiveResources[i]]!)
            }
            var wealthAmount:Int = 0
            var didBuild:Bool = false
            
            if valueOfPushed == 1{ //car build pressed
              if PossibleValuesOfActiveResources["Iron"]! >= 1500 && PossibleValuesOfActiveResources["Rubber"]! >= 1000 && PossibleValuesOfActiveResources["Oil"]! >= 800 && PossibleValuesOfActiveResources["Glass"]! >= 1200
                {
                    testForActiveResources(Resource: "Iron", Amount: 1500)
                    testForActiveResources(Resource: "Rubber", Amount: 1000)
                    testForActiveResources(Resource: "Oil", Amount: 800)
                    testForActiveResources(Resource: "Glass", Amount: 1200)
                    wealthAmount = 30000
                    didBuild = true;
                    trackBoughtThings["Car"]! += 1
                }
              else
                {
                    //they don't have enough, deny them!!!!
                    denySoundPlayer.play()
                    visuallyDeny(Distance: 30)
                }
            
            }
            else if valueOfPushed == 2{ //house build pressed
                if PossibleValuesOfActiveResources["Brick"]! >= 1500 && PossibleValuesOfActiveResources["Lumber"]! >= 2000 && PossibleValuesOfActiveResources["Stone"]! >= 1500
                {
                    testForActiveResources(Resource: "Brick", Amount: 1500)
                    testForActiveResources(Resource: "Lumber", Amount: 2000)
                    testForActiveResources(Resource: "Stone", Amount: 1500)
                    wealthAmount = 18500
                    didBuild = true;
                    trackBoughtThings["House"]! += 1
                }
                else
                {
                    //they don't have enough, deny them!!!!
                    denySoundPlayer.play()
                    visuallyDeny(Distance: 30)
                }
            
            }
            else if valueOfPushed == 3{ //boat build pressed
                if PossibleValuesOfActiveResources["Lumber"]! >= 2000 && PossibleValuesOfActiveResources["Rope"]! >= 1000 && PossibleValuesOfActiveResources["Wool"]! >= 1500
                {
                    testForActiveResources(Resource: "Lumber", Amount: 2000)
                    testForActiveResources(Resource: "Rope", Amount: 1000)
                    testForActiveResources(Resource: "Wool", Amount: 1500)
                    wealthAmount = 18000
                    didBuild = true
                    trackBoughtThings["Boat"]! += 1
                }
                else
                {
                    //they don't have enough, deny them!!!!
                    denySoundPlayer.play()
                    visuallyDeny(Distance: 30)
                }
            }
            else if valueOfPushed == 4{ //bread build pressed
                if PossibleValuesOfActiveResources["Wheat"]! >= 1500 && PossibleValuesOfActiveResources["Spices"]! >= 1500
                {
                    testForActiveResources(Resource: "Wheat", Amount: 1500)
                    testForActiveResources(Resource: "Spices", Amount: 1500)
                    wealthAmount = 10000
                    didBuild = true
                    trackBoughtThings["Bread"]! += 1
                }
                else
                {
                    //they don't have enough, deny them!!!!
                    denySoundPlayer.play()
                    visuallyDeny(Distance: 30)
                }
                
            }
            else if valueOfPushed == 5{ //candy build pressed
                if PossibleValuesOfActiveResources["Wheat"]! >= 1000 && PossibleValuesOfActiveResources["Sugar"]! >= 1500
                {
                    testForActiveResources(Resource: "Wheat", Amount: 1000)
                    testForActiveResources(Resource: "Sugar", Amount: 1500)
                    wealthAmount = 9000
                    didBuild = true
                    trackBoughtThings["Candy"]! += 1
                }
                else
                {
                    //they don't have enough, deny them!!!!
                    denySoundPlayer.play()
                    visuallyDeny(Distance: 30)
                }
            }
            if (didBuild) //this will be true if we were able to successfully build one of these items
            {
                UsersInformation.wealthOfCurrentUser += wealthAmount
                doAllPreventativeSavingStuff()
                animateTheWealthButton(amount: wealthAmount)
                buildSoundPlayer.play()
            }
        }
    }
    func animateTheWealthButton(amount:Int)
    {
        /*
            This function takes an amount, and makes it pop off the wealth thing, so basically it creates a nice little animation.
        */
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
        fakeAmount.textColor = UIColor(displayP3Red: 0.36, green: 0.79, blue: 0.38, alpha: 1)
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
        let classReference = Database.database().reference().child(UsersInformation.classWeAreIn).child("NamesOfUsers").child(UsersInformation.currentUsersUsername)
        var newResourcesAndWealth: [String:Int] = UsersInformation.currentUsersResources
        var profitGained:Int = 0
        newResourcesAndWealth["Wealth"] = UsersInformation.wealthOfCurrentUser
        classReference.setValue(newResourcesAndWealth)
        //track the bought products
        var JSONToPost: [String: Any] = [:]
        for product in trackBoughtThings
        {
            if product.value != 0
            {
                if product.key == "Car"
                {
                    profitGained = product.value * 30000
                }
                else if product.key == "House"
                {
                    profitGained = product.value * 18500
                }
                else if product.key == "Boat"
                {
                    profitGained = product.value * 18000
                }
                else if product.key == "Bread"
                {
                    profitGained = product.value * 10000
                }
                else{
                    profitGained = product.value * 9000
                }
                JSONToPost["Creator"] = UsersInformation.currentUsersUsername
                JSONToPost["Profit"] = profitGained
                JSONToPost["BoughtProduct"] = product.key
                JSONToPost["AmountBought"] = product.value
                Database.database().reference(withPath: UsersInformation.classWeAreIn).child("BoughtThings").childByAutoId().setValue(JSONToPost)
                JSONToPost = [:]
            }
        }
        trackBoughtThings = ["Car": 0, "House": 0, "Boat": 0, "Bread": 0, "Candy": 0]
    }
    
    @IBAction func productsButtonDidTouch(_ sender: Any) {
        buttonSoundPlayer.play()
        manipulateTheOutlets(myBool: true)
    }
    @IBAction func assetsButtonDidTouch(_ sender: Any) {
        buttonSoundPlayer.play()
        self.performSegue(withIdentifier: "toAssets", sender: nil)
    }
    func makeInformationWait()
    {
        //This timer is needed so that the information doesn't appear on top of the products while they are moving. once they have finished moving, plop in the info.
        informationIsNeeded = true
        // this informationIsNeeded Variable is necissary because there was a case where, if you opened and closed the product button before this timer had fired, the moveInformationAway function would be called first, and the moveInInformation function would be called second, and the information would be left on the screen permenantly.
        _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(createInformation), userInfo: nil, repeats: false)
    }
    @IBAction func carWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        if valueOfPushed != 1
        {
            if alreadyPushed == false{
                valueOfPushed = 1
                moveButtons(selectorX: 1)
                makeInformationWait()
                alreadyPushed = true
            }
            else{
                deleteInformation()
                carWasTouched(Any.self)}
        }
        else{
            deleteInformation()
        }
    }
    @IBAction func houseWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        if valueOfPushed != 2
        {
            if alreadyPushed == false{
                valueOfPushed = 2
                moveButtons(selectorX: 1)
                makeInformationWait()
                alreadyPushed = true
            }
            else{
                deleteInformation()
                houseWasTouched(Any.self)}
        }
        else{
            deleteInformation()
            print("Casa and Already pushed: \(alreadyPushed)")
        }
    }
    @IBAction func boatWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        if valueOfPushed != 3
        {
            if alreadyPushed == false{
                valueOfPushed = 3
                moveButtons(selectorX: 1)
                makeInformationWait()
                alreadyPushed = true
            }
            else{
                deleteInformation()
                boatWasTouched(Any.self)}
        }
        else{
            deleteInformation()
        }
    }
    @IBAction func breadWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        if valueOfPushed != 4
        {
            if alreadyPushed == false
            {
                valueOfPushed = 4
                moveButtons(selectorX: 1)
                makeInformationWait()
                alreadyPushed = true
            }
            else{
                deleteInformation()
                breadWasTouched(Any.self)}
            }
        else{
            deleteInformation()
        }
    }
    @IBAction func candyWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        if valueOfPushed != 5
        {
            if alreadyPushed == false{
                valueOfPushed = 5
                moveButtons(selectorX: 1)
                makeInformationWait()
                alreadyPushed = true
            }
            else{
                deleteInformation()
                candyWasTouched(Any.self)}
        }
        else
        {
            deleteInformation()
        }
    }
    
    func moveButtons(selectorX:CGFloat)
    {
        slideSoundPlayer.play()
        let distanceToMove:CGFloat = 100
        for i in 1...5
        {
            let Button = self.view.viewWithTag(i)
            if i <= valueOfPushed
            {
                if (i == 1 && valueOfPushed == 1)
                {
                    //if we selected the top item, the car, don't push it up, or it will exit the screen which I don't like.
                }
                else
                {
                    //move everything above the selected item up, to make room for the requirements.
                    UIView.animate(withDuration: 0.5, animations: {
                        Button!.center = CGPoint(x: Button!.center.x, y: Button!.center.y - (distanceToMove * selectorX))
                    })
                }
            }
            else if (i > 1 && valueOfPushed == 1)
            {
                // the only time we move the resources down, if we selected the car, the top item.
                UIView.animate(withDuration: 0.5, animations: {
                    Button!.center = CGPoint(x: Button!.center.x, y: Button!.center.y + (distanceToMove * selectorX))
                })
            }
        }
    }
    func testForActiveResources(Resource:String, Amount:Int)
    {
        if UsersInformation.currentUsersResources[Resource] != nil
        {
            UsersInformation.currentUsersResources[Resource]! -= Amount
            if (UsersInformation.currentUsersResources[Resource] == 0 && UsersInformation.settings["FixedResources"]! == false)
            {
                Database.database().reference().child(UsersInformation.classWeAreIn).child("NamesOfUsers").child(UsersInformation.currentUsersUsername).child(Resource).removeValue()
                UsersInformation.currentUsersResources[Resource] = nil
            }
        }
        else if UsersInformation.currentUsersResources["\(Resource)X"] != nil
        {
            UsersInformation.currentUsersResources["\(Resource)X"]! += Amount
        }
    }
    @objc func createInformation()
    {
        if informationIsNeeded && alreadyPushed
        {
            RequirementsLabel.isHidden = false
            ProfitLabel.isHidden = false
            BuildButton.isHidden = false
            BuildBackGround.isHidden = false
            let distanceToMoveDown:CGFloat = 10
            let ButtonPushed = self.view.viewWithTag(valueOfPushed)
            RequirementsLabel.frame = CGRect(x: 10, y: ((ButtonPushed?.frame.maxY)! + distanceToMoveDown), width: self.view.frame.width - 20, height: CGFloat(30))
        
            ProfitLabel.frame = CGRect(x: 0, y: (RequirementsLabel.frame.maxY + (distanceToMoveDown/4)), width: self.view.frame.width, height: CGFloat(20))
            
        
            if valueOfPushed == 1{
                RequirementsLabel.text = "Requires 1,500 Iron, 1,200 Glass, 1,000 Rubber, and 800 Oil."
                ProfitLabel.text = "Profit: $30,000"
                BuildButton.setTitle("Build Car", for: UIControlState.normal)
            }
            else if valueOfPushed == 2{
                RequirementsLabel.text = "Requires 2,000 Lumber, 1,500 Brick, and 1,500 Stone."
                ProfitLabel.text = "Profit: $18,500"
                BuildButton.setTitle("Build House", for: UIControlState.normal)
            }
            else if valueOfPushed == 3{
                RequirementsLabel.text = "Requires 2,000 Lumber, 1,500 Wool and 1,000 Rope."
                ProfitLabel.text = "Profit: $18,000"
                BuildButton.setTitle("Build Boat", for: UIControlState.normal)
            }
            else if valueOfPushed == 4{
                RequirementsLabel.text = "Requires 1,500 Wheat, and 1,500 Spices."
                ProfitLabel.text = "Profit: $10,000"
                BuildButton.setTitle("Build Bread", for: UIControlState.normal)
            }
            else if valueOfPushed == 5{
                RequirementsLabel.text = "Requires 1,000 Wheat, and 1,500 Sugar."
                ProfitLabel.text = "Profit: $9,000"
                BuildButton.setTitle("Build Candy", for: UIControlState.normal)
            }
            //needed to adjust buildbutton after it's text had been selected.
            
            let buildbuttonFrame = CGSize(width: 150, height: 20)
            let buildbuttonPosition = CGPoint(x: self.view.frame.width/2 , y: ProfitLabel.frame.maxY + (distanceToMoveDown/4))
            BuildButton.frame = CGRect(origin: buildbuttonPosition, size: buildbuttonFrame)
            BuildButton.sizeToFit()
            BuildButton.center.x = self.view.frame.width/2
            BuildBackGround.frame = CGRect(x: 0, y: 0, width: BuildButton.frame.width + 12, height: BuildButton.frame.height)
            BuildBackGround.center = BuildButton.center
            informationIsNeeded = false
        }
        
    }
    func deleteInformation()
    {
        if alreadyPushed == true
        {
            moveButtons(selectorX: -1)
            alreadyPushed = false
            RequirementsLabel.isHidden = true
            ProfitLabel.isHidden = true
            BuildButton.isHidden = true
            BuildBackGround.isHidden = true
            valueOfPushed = 0
        }
        
    }
    func visuallyDeny(Distance:CGFloat)
    {
        if (Distance > 0)
        {
            let duration:Double = 0.1
            UIView.animate(withDuration: duration, animations: {
                self.BuildButton.center = CGPoint(x: self.BuildButton.center.x - Distance , y: self.BuildButton.center.y)
                self.BuildBackGround.center = CGPoint(x: self.BuildBackGround.center.x - Distance , y: self.BuildBackGround.center.y)
            }) { (true) in
                UIView.animate(withDuration: duration * 2, animations: {
                    self.BuildButton.center = CGPoint(x: self.BuildButton.center.x + Distance * 2, y: self.BuildButton.center.y)
                    self.BuildBackGround.center = CGPoint(x: self.BuildBackGround.center.x + Distance * 2, y: self.BuildBackGround.center.y)
                }) { (true) in
                    UIView.animate(withDuration: duration, animations: {
                        self.BuildButton.center = CGPoint(x: self.BuildButton.center.x - Distance, y: self.BuildButton.center.y)
                        self.BuildBackGround.center = CGPoint(x: self.BuildBackGround.center.x - Distance , y: self.BuildBackGround.center.y)
                    }) { (true) in
                        self.visuallyDeny(Distance: Distance - 25)
                    }
                }
            }
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            deleteInformation()
    }
    
    @IBOutlet var carProduct: UIButton!
    @IBOutlet var houseProduct: UIButton!
    @IBOutlet var boatProduct: UIButton!
    @IBOutlet var breadProduct: UIButton!
    @IBOutlet var candyProduct: UIButton!
    @IBOutlet var productsButton: UIButton!
    @IBOutlet var productsButtonLabel: UILabel!
    @IBOutlet var productsInfoLabel: UILabel!
    @IBOutlet var assetsButton: UIButton!
    @IBOutlet var assetsButtonLabel: UILabel!
    @IBOutlet var assetsInfoLabel: UILabel!
}
