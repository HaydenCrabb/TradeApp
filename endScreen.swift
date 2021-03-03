//
//  endScreen.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 8/2/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class endScreen:UIViewController {

    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    
    override func viewDidLoad() {
        let buttonClickPath = Bundle.main.path(forResource: "buttonClick.mp3", ofType: nil)!
        let buttonClickSound = NSURL(fileURLWithPath: buttonClickPath)
        do {
            try buttonSoundPlayer = AVAudioPlayer(contentsOf: buttonClickSound as URL)
            buttonSoundPlayer.prepareToPlay()
        } catch {
            print("Bummer....")
        }
        //remove all class stuff
        Database.database().reference(withPath: "AllUsers").child(UsersInformation.currentUsersUID).child("ActiveClass").removeValue()
        UsersInformation.classWeAreIn = "Z"
        UsersInformation.weAreInClass = false
        UsersInformation.classIsActive = false
        UsersInformation.endDateOfClass = 0
        UsersInformation.multiplier = 1.0
        UsersInformation.userWeAreTradingWith = "The Crabbster"
        UsersInformation.currentUsersResources = [:]
        UsersInformation.currentUsersActiveResources = []
        UsersInformation.clickedUsersResources = [:]
        UsersInformation.currentUsersResources = [:]
        UsersInformation.individualResourceMultiplier = [:]
        UsersInformation.theirIndividualResourceMultiplier = [:]
        UsersInformation.ActivationDate = 0
    }
    
    @IBAction func endButtonWasTouched(_ sender: Any) {
        buttonSoundPlayer.play()
        self.performSegue(withIdentifier: "finallyOver", sender: nil)
    }
}
