//
//  SignupViewController.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 2/27/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class signUpViewController:UIViewController
{
    let Users = Database.database().reference(withPath: "AllUsers")
    var emailEntered = "x"
    var cleanedUsername:String = "x"
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    let ourActivityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
    var aboveDistance:CGFloat = 0
    var belowDistance:CGFloat = 0

    override func viewDidLoad() {
        //initialize sound
        ourActivityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        ourActivityIndicator.hidesWhenStopped = true
        ourActivityIndicator.frame = CGRect(x: 0, y: 0, width: self.view.frame.width/3, height: self.view.frame.width/3)
        ourActivityIndicator.center = self.view.center
        self.view.addSubview(ourActivityIndicator)
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
        Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil
            {
                self.reset()
                UsersInformation.currentUsersUID = user!.uid
                UsersInformation.currentUsersUsername = self.cleanedUsername
                self.performSegue(withIdentifier: "signUpToOverview", sender: nil)
            }
        })
        belowDistance = SignUpButton.frame.minY - UsernameTextEnter.frame.maxY
        aboveDistance = UsernameInfoLabel.frame.minY - passwordTextEnter.frame.maxY
    }
    
    @IBAction func backButtonDidTouch(_ sender: Any) {
        backTickSoundPlayer.play()
        reset()
        performSegue(withIdentifier: "backToSignIn", sender: nil)
        
    }
    @IBAction func signUpDidTouch(_ sender: Any) {
        buttonSoundPlayer.play()
        if emailTextEnter.text != "" && passwordTextEnter.text != ""  && UsernameTextEnter.text != ""
        {
            removeSpecialCharsFromString(text: UsernameTextEnter.text!)
            let alert = UIAlertController(title: "Signing Up...", message: "Your new username will be: \(cleanedUsername) is that okay?",    preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
                self.createNewestUser()
            }))
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction) in
                alert.dismiss(animated: true, completion: nil)
            }) )
            self.present(alert, animated: true, completion: nil)
        }
        else
        {
            errorMessageLabel.isHidden = false
            errorMessageLabel.text = "Please fill in all fields."
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if emailTextEnter.isHidden == true
        {
            //the the username box has been brought up and we need to bring it down.
            UIView.animate(withDuration: 0.5, animations: {
                self.above.constant = self.aboveDistance
                self.below.constant = self.belowDistance
                self.view.layoutIfNeeded()
            }) { (true) in
                self.emailTextEnter.isHidden = false
                self.passwordTextEnter.isHidden = false

            }
            
        }
        self.view.endEditing(true)
    }
    func createActivityIndicator()
    {
        ourActivityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
    }
    func endActivityIndicator()
    {
        ourActivityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    func createNewestUser()
    {
        ourActivityIndicator.startAnimating()
        Auth.auth().createUser(withEmail: self.emailTextEnter.text!, password: self.passwordTextEnter.text!) { user, error in
            self.ourActivityIndicator.stopAnimating()
            if error == nil {
                
                let newUsers = self.Users.child("\(user!.user.uid)")
                newUsers.child("Username").setValue("\(self.cleanedUsername)")
                Auth.auth().signIn(withEmail: self.emailTextEnter.text!, password: self.passwordTextEnter.text!)
            }
            else
            {
                self.errorMessageLabel.isHidden = false
                
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    
                    switch errCode {
                    case .invalidEmail:
                        self.errorMessageLabel.text = "Please enter a valid email."
                    case .emailAlreadyInUse:
                        self.errorMessageLabel.text = "That email is already in use."
                    case .weakPassword:
                        self.errorMessageLabel.text = "Your Password is to weak."
                    default:
                        self.errorMessageLabel.text = "Unknown error."
                    }
                }
                
                
            }
        }
    }
    func removeSpecialCharsFromString(text: String)
    {
        let okayChars : Set<Character> =
            Set(".#$[]")
        cleanedUsername = String(text.filter {!okayChars.contains($0) })
    }
    
    @IBAction func bottomTextBoxTouched(_ sender: Any) {
       //for some reason, When the keyboard is already up, this freaks out.
        emailTextEnter.isHidden = true
        passwordTextEnter.isHidden = true
        
        var distance:CGFloat = SignUpButton.frame.minY - errorMessageLabel.frame.maxY
        distance = distance - (UsernameTextEnter.frame.maxY - UsernameInfoLabel.frame.minY)
        let aboveDistance:CGFloat = passwordTextEnter.frame.maxY - errorMessageLabel.frame.maxY
        
        UIView.animate(withDuration: 0.5) {
            self.below.constant = distance
            self.above.constant = (aboveDistance * -1)
            self.view.layoutIfNeeded()
        }
    }
    func reset()
    {
        errorMessageLabel.isHidden = true
        emailTextEnter.text = ""
        passwordTextEnter.text = ""
    }
    
    @IBOutlet var UsernameInfoLabel: UILabel!
    
    @IBOutlet var SignUpButton: UIButton!
    @IBOutlet var UsernameTextEnter: UITextField!
    @IBOutlet var errorMessageLabel: UILabel!
    @IBOutlet var emailTextEnter: UITextField!
    @IBOutlet var above: NSLayoutConstraint!
    @IBOutlet var below: NSLayoutConstraint!
    @IBOutlet var passwordTextEnter: UITextField!
}
