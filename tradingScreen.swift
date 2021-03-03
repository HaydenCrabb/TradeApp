//
//  tradingScreen.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 4/6/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class tradingScreen : UIViewController
{
    var UsersInOurClassArray: [String] = []
    var ButtonInView:Int = 1
    var boxThing:UIImageView = UIImageView()
    var exitButton:UIButton = UIButton()
    var tradeButton:UIButton = UIButton()
    var tradeButtonLabel:UILabel = UILabel()
    var informationalStackView:UIStackView = UIStackView()
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        //initialize sounds
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

        //initialize tradeButton
        TradesButton.layer.masksToBounds = true
        TradesButton.layer.cornerRadius = 5
        TradesButton.layer.borderWidth = 2
        let darkGrey = UIColor(displayP3Red: 35/255, green: 31/255, blue: 32/255, alpha: 1)
        TradesButton.layer.borderColor = darkGrey.cgColor
        let lightGray = UIColor(displayP3Red: 142/255, green: 139/255, blue: 139/255, alpha: 1)
        TradesButton.layer.backgroundColor = lightGray.cgColor
        NoPlayersLabel.isHidden = true
        //flip up arrow
        upArrow.isHidden = true
        downArrow.isHidden = true
        let ButtonImage:UIImage = UIImage(named: "upAndDownArrow")!
        let flipedCountryImage:UIImage = UIImage(cgImage: ButtonImage.cgImage!, scale: ButtonImage.scale, orientation: UIImageOrientation.downMirrored)
        upArrow.setImage(flipedCountryImage, for: .normal)
        
        findUsersOfYourClass()
        
        //see if we have any trades.
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn)
        ref.child("Trades").queryOrdered(byChild: "To").queryEqual(toValue: UsersInformation.currentUsersUsername).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists()
            {
                let allTrades = snapshot.value as! [String : [String:Any]]
                var activeTrades:Int = 0
                for trade in allTrades
                {
                    if trade.value["Active"] as! Int == 0
                    {
                        activeTrades = activeTrades + 1
                    }
                }
                if activeTrades > 0
                {
                    let showCircle:UILabel = UILabel()
                    showCircle.frame = CGRect(x: 0, y: 0, width: CGFloat(self.TradesButton.frame.height/3), height: CGFloat(self.TradesButton.frame.height/3))
                    showCircle.center = CGPoint(x: self.TradesButton.frame.minX, y: self.TradesButton.frame.minY)
                    showCircle.backgroundColor = UIColor.red
                    showCircle.layer.masksToBounds = true
                    showCircle.layer.cornerRadius = showCircle.frame.height/2
                    self.view.addSubview(showCircle)
                    let tradeIndicator = UILabel()
                    tradeIndicator.frame = CGRect(x: 0, y: 0, width: showCircle.frame.width/1.5, height: showCircle.frame.height/1.5)
                    tradeIndicator.center = CGPoint(x: showCircle.frame.midX, y: showCircle.frame.midY)
                    tradeIndicator.textAlignment = .center
                    tradeIndicator.text = "\(activeTrades)"
                    tradeIndicator.textColor = UIColor.white
                    tradeIndicator.adjustsFontSizeToFitWidth = true
                    self.view.addSubview(tradeIndicator)
                }
            }
        })
        
    }

    func findUsersOfYourClass()
    {
        let ourActivityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
        ourActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        ourActivityIndicator.hidesWhenStopped = true
        ourActivityIndicator.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/3, height: self.view.frame.width/3)
        ourActivityIndicator.center = self.view.center
        self.view.addSubview(ourActivityIndicator)
        ourActivityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        let UsersClass = Database.database().reference(withPath: UsersInformation.classWeAreIn)
        UsersClass.child("AllUserNames").observeSingleEvent(of: .value, with: { (snapshot) in
            ourActivityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            if snapshot.exists()
            {
                let UsersInOurClass = snapshot.value as! [String : String]
                for user in UsersInOurClass
                {
                    if user.key != UsersInformation.currentUsersUsername && user.value == "Active"
                    {
                        self.UsersInOurClassArray.append(user.key)
                        self.createButtonsFromUsers(nextUser: user.key)
                    }
                }
                self.checkIfAButtonIsNeeded()
            }
            else
            {
                print("Error Snapshot Does not exist")
            }
        })
        
    }
    
    func createButtonsFromUsers(nextUser:String)
    {
        //buttons with smaller tag are at top of stack.
        let numberOfButtons:Int = UsersInOurClassArray.count
        let CountryButton:UIButton = UIButton()
        CountryButton.frame = CGRect(x: 0, y: 0 , width: self.view.frame.width/3, height: self.view.frame.height/4)
        CountryButton.center = CGPoint(x: self.view.frame.width/2, y: self.view.frame.height/2 + (self.view.frame.height * CGFloat(numberOfButtons - 1)))
        CountryButton.setImage(#imageLiteral(resourceName: "CountryIcon"), for: .normal)
        CountryButton.contentMode = .scaleAspectFit
        CountryButton.tag = numberOfButtons
        CountryButton.addTarget(self, action: #selector(countryButtonWasPushed(pressedButton:)), for: .touchUpInside)
        self.view.addSubview(CountryButton)
        let CountryText:UILabel = UILabel()
        CountryText.adjustsFontSizeToFitWidth = true
        CountryText.textAlignment = .center
        CountryText.frame = CGRect(x: CountryButton.frame.minX, y:CountryButton.frame.maxY, width: self.view.frame.width/3, height: 25)
        CountryText.text = nextUser
        CountryText.tag = numberOfButtons + 100230
        self.view.addSubview(CountryText)
    }
    @objc func countryButtonWasPushed(pressedButton: UIButton)
    {
        buttonSoundPlayer.play()
        let buttonToWork = UsersInOurClassArray[(pressedButton.tag) - 1]
        UsersInformation.userWeAreTradingWith = buttonToWork
        let childToSnag = Database.database().reference(withPath: UsersInformation.classWeAreIn).child("NamesOfUsers").child(buttonToWork)
        childToSnag.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists()
            {
                self.upArrow.isEnabled = false
                self.downArrow.isEnabled = false
                UsersInformation.clickedUsersActiveResources = []
                UsersInformation.clickedUsersResources = snapshot.value as! [String:Int]
                UsersInformation.clickedUsersResources.removeValue(forKey: "Wealth")
                for (key,value) in UsersInformation.clickedUsersResources
                {
                    if key.contains("X")
                    {
                        let Xkey:String = String(key.dropLast())
                        UsersInformation.clickedUsersActiveResources.append(Xkey)
                        UsersInformation.clickedUsersResources.removeValue(forKey: key)
                        UsersInformation.clickedUsersResources[Xkey] = value
                    }
                }
                self.moveInGreyBox(pressedButton: pressedButton)
            }
        })
    }
    
    func moveInGreyBox(pressedButton:UIButton)
    {
        //initialize box
        boxThing.image = UIImage(named: "greyBox")
        let distanceToWall = self.view.frame.maxX - pressedButton.frame.maxX
        let boxFrame:CGRect = CGRect(x: 0, y: 0, width: distanceToWall - 6, height: self.view.frame.height/2.5)
        boxThing.frame = boxFrame
        boxThing.center = CGPoint(x: pressedButton.frame.maxX + (distanceToWall/2), y: self.view.frame.height/2)
        self.view.addSubview(boxThing)
        //initialize backButton
        let exitButtonImage:UIImage = UIImage.init(named: "BackButton")!
        exitButton.setImage(exitButtonImage, for: .normal)
        let exitButtonFrame:CGRect = CGRect(x: 0, y: 0, width: boxThing.frame.width/3, height: boxThing.frame.height/7)
        exitButton.frame = exitButtonFrame
        exitButton.center = CGPoint(x: boxThing.frame.minX + (exitButton.frame.width/2) + 2, y: boxThing.frame.minY + 2 + exitButton.frame.height/2)
        exitButton.addTarget(self, action: #selector(moveAwayGreyBox), for: UIControlEvents.touchUpInside)
        self.view.addSubview(exitButton)
        //initialize tradeButton
        let tradeButtonImage:UIImage = UIImage.init(named: "Main Button")!
        tradeButton.setBackgroundImage(tradeButtonImage, for: .normal)
        tradeButton.frame = CGRect(x: 0, y: 0, width: boxThing.frame.width/2.5, height: boxThing.frame.height/7)
        tradeButton.center = CGPoint(x: boxThing.frame.midX, y: boxThing.frame.maxY - (tradeButton.frame.width/2))
        tradeButton.addTarget(self, action: #selector(tradeButtonWasPushed), for: UIControlEvents.touchUpInside)
        if UsersInformation.classIsActive == false
        {
            tradeButton.isEnabled = false
        }
        self.view.addSubview(tradeButton)
        //initialize TradeButtonLabel
        tradeButtonLabel.frame = CGRect(x: 0, y: 0, width: (boxThing.frame.width/3.5) - 5, height: (boxThing.frame.height/7) - 2)
        tradeButtonLabel.textColor = UIColor.black
        tradeButtonLabel.text = "Trade"
        tradeButtonLabel.textAlignment = NSTextAlignment.center
        tradeButtonLabel.center = CGPoint(x: tradeButton.frame.midX, y: tradeButton.frame.midY - 2)
        tradeButtonLabel.adjustsFontSizeToFitWidth = true
        self.view.addSubview(tradeButtonLabel)
        //initialize informationalStackView
        informationalStackView.frame = CGRect(x: 0, y: 0, width: boxThing.frame.width, height: boxThing.frame.height - (tradeButton.frame.height * 2.5))
        informationalStackView.center = CGPoint(x: boxThing.frame.midX, y: boxThing.frame.midY - 2)
        informationalStackView.axis = .vertical
        informationalStackView.alignment = .fill
        informationalStackView.distribution = .equalSpacing
        self.view.addSubview(informationalStackView)
        populateInformationalStackView()
    }
    @objc func moveAwayGreyBox()
    {
        boxThing.removeFromSuperview()
        exitButton.removeFromSuperview()
        tradeButton.removeFromSuperview()
        tradeButtonLabel.removeFromSuperview()
        informationalStackView.removeFromSuperview()
        upArrow.isEnabled = true
        downArrow.isEnabled = true
        
    }
    @objc func tradeButtonWasPushed()
    {
        self.performSegue(withIdentifier: "toTradingActiveScreen", sender: nil)
    }
    func populateInformationalStackView()
    {
        if informationalStackView.subviews.count == 0
        {
            for (key,_) in UsersInformation.clickedUsersResources
            {
                let nextLabel:UILabel = UILabel()
                nextLabel.textColor = UIColor.black
                nextLabel.text = "\(key)"
                nextLabel.textAlignment = .center
                nextLabel.adjustsFontSizeToFitWidth = true
                informationalStackView.addArrangedSubview(nextLabel)
            }
        }
        else
        {
            for subview in informationalStackView.subviews
            {
                subview.removeFromSuperview()
            }
            populateInformationalStackView()
        }
        
    }
    
    @IBAction func upButtonWasPressed(_ sender: Any) {
        buttonSoundPlayer.play()
        for i in 1...UsersInOurClassArray.count
        {
            let view:UIView = self.view.viewWithTag(i)!
            let textView:UIView = self.view.viewWithTag(i + 100230)!
            UIView.animate(withDuration: 0.3, animations: {
                view.center = CGPoint(x: self.view.frame.width/2, y: view.frame.midY + self.view.frame.height)
                textView.center = CGPoint(x: self.view.frame.width/2, y: textView.frame.midY + self.view.frame.height)
            })
        }
        ButtonInView -= 1
        checkIfAButtonIsNeeded()
    }
    
    @IBAction func downButtonWasPressed(_ sender: Any) {
        buttonSoundPlayer.play()
        for i in 1...UsersInOurClassArray.count
        {
            let view:UIView = self.view.viewWithTag(i)!
            let textView:UIView = self.view.viewWithTag(i + 100230)!
            UIView.animate(withDuration: 0.3, animations: {
                view.center = CGPoint(x: self.view.frame.width/2, y: view.frame.midY - self.view.frame.height)
                textView.center = CGPoint(x: self.view.frame.width/2, y: textView.frame.midY - self.view.frame.height)
            })
        }
        ButtonInView += 1
        checkIfAButtonIsNeeded()
    }
    func checkIfAButtonIsNeeded()
    {
        var top:Bool = false
        var bottom:Bool = false
        if UsersInOurClassArray.count == 1 || UsersInOurClassArray.count == 0
        {
            top = true
            bottom = true
            if UsersInOurClassArray.count == 0
            {
                NoPlayersLabel.isHidden = false
            }
        }
        else
        {
            if ButtonInView == 1
            {
                top = true
            }
            else if ButtonInView == UsersInOurClassArray.count
            {
                bottom = true
            }
        }
        upArrow.isHidden = top
        downArrow.isHidden = bottom
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveAwayGreyBox()
    }
    
    @IBAction func activeTradesWasPressed(_ sender: Any) {
        buttonSoundPlayer.play()
        self.performSegue(withIdentifier: "toActiveTrades", sender: nil)
        
    }
    @IBAction func backButtonWasTouched(_ sender: Any) {
        backTickSoundPlayer.play()
        self.performSegue(withIdentifier: "tradeBackToOverview", sender: nil)
    }
    
    
    @IBOutlet var NoPlayersLabel: UILabel!
    @IBOutlet var TradesButton: UIButton!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var upArrow: UIButton!
    @IBOutlet var downArrow: UIButton!
    

}
