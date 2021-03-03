//
//  resourceScreen.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 4/6/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class resourceScreen : UIViewController
{
    
    var resourceWeAreOn:Int = 0
    var allOurResource:[String] = []
    var resourceUpdater:Timer = Timer()
    var resourcePictureUpdater:Timer = Timer()
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    
    
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
        createButtons()
        pictureFrame.image = UIImage(named: "resource\(allOurResource[0])")
        let ref = Database.database().reference(withPath: UsersInformation.classWeAreIn).child("NamesOfUsers").child(UsersInformation.currentUsersUsername)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists()
            {
                var newSnapshot: [String : Int] = snapshot.value as! [String : Int]
                newSnapshot.removeValue(forKey: "Wealth")
                if newSnapshot != UsersInformation.currentUsersResources
                {
                    UsersInformation.currentUsersResources = newSnapshot
                    for label in self.mainStackView.subviews
                    {
                        label.removeFromSuperview()
                    }
                    self.createButtons()
                }
            }
        })
        resourcePictureUpdater = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(pictures), userInfo: nil, repeats: true)
    }
    @objc func pictures()
    {
        if mainStackView.arrangedSubviews.count != 0
        {
            if resourceWeAreOn != UsersInformation.currentUsersResources.count - 1
            {
                resourceWeAreOn += 1
            }
            else
            {
                resourceWeAreOn = 0
            }
            pictureFrame.image = UIImage(named: "resource\(allOurResource[resourceWeAreOn])")
        }
    }

    func createButtons()
    {
        print("Current Users Resources: \(UsersInformation.currentUsersResources)")
        var currentResource:String
        var counter:Int = 0
        print(UsersInformation.currentUsersResources)
        for resource in UsersInformation.currentUsersResources
        {
            if resource.key.last == "X"
            {
                currentResource = String(resource.key.dropLast())
                counter += 1
            }
            else
            {
                currentResource = resource.key
            }
            actuallyCreateButton(resource: currentResource, value: resource.value, counter: counter)
        }
        if UsersInformation.classIsActive
        {
            resourceUpdater = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateResources), userInfo: nil, repeats: true)
        }
    }
    func actuallyCreateButton(resource:String, value:Int, counter:Int)
    {
        let NextLabel:UILabel = UILabel()
        NextLabel.textAlignment = .center
        NextLabel.font = UIFont(name: "Helvetica", size: 22)
        let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
        if UsersInformation.classIsActive && UsersInformation.currentUsersActiveResources.contains(resource)
        {
            NextLabel.text = "\(resource): \(Int(Float(currentDate - (UsersInformation.ActivationDate + value)) * UsersInformation.individualResourceMultiplier[resource]!))"
            NextLabel.tag = counter
            print("Creating resource with tag i: \(counter)")
        }
        else
        {
            NextLabel.text = "\(resource): \(value)"
        }
        NextLabel.center.x = self.view.frame.width/2
        mainStackView.addArrangedSubview(NextLabel)
        allOurResource.append(resource)
        print("Actually creating the button: \(resource) with value: \(value)")
    }
    @objc func updateResources()
    {
        if (UsersInformation.currentUsersActiveResources.count > 0)
        {
            print(UsersInformation.currentUsersActiveResources)
            for i in 1...UsersInformation.currentUsersActiveResources.count //Crash occurs here!!!
            {
                print(i)
                let labelToEdit:UILabel = self.view.viewWithTag(i) as! UILabel
                let labelWithoutX: String = String(UsersInformation.currentUsersActiveResources[i - 1])
                let currentDate = Int(truncating: NSNumber(value:Date().timeIntervalSince1970))
                let valueOfResource = Int(Float(currentDate - (UsersInformation.ActivationDate + UsersInformation.currentUsersResources["\(UsersInformation.currentUsersActiveResources[i - 1])X"]!)) * UsersInformation.individualResourceMultiplier[labelWithoutX]!)
                labelToEdit.text = "\(labelWithoutX): \(valueOfResource)"
            }
        }
    }
    @IBAction func backButtonWasTouched(_ sender: Any) {
        backTickSoundPlayer.play()
        resourceUpdater.invalidate()
        resourcePictureUpdater.invalidate()
        self.performSegue(withIdentifier: "resourcesBackToOverview", sender: nil)
    }


    @IBOutlet var pictureFrame: UIImageView!
    @IBOutlet var mainStackView: UIStackView!
}
