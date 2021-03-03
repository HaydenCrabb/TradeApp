//
//  LoginViewController.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 2/27/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class loginViewController:UIViewController
{
    var stopThat:Bool = true
    var buttonSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    override func viewDidLoad() {
        //initialize sound
        let buttonClickPath = Bundle.main.path(forResource: "buttonClick.mp3", ofType: nil)!
        let buttonClickSound = NSURL(fileURLWithPath: buttonClickPath)
        do {
            try buttonSoundPlayer = AVAudioPlayer(contentsOf: buttonClickSound as URL)
            buttonSoundPlayer.prepareToPlay()
        } catch {
            print("Bummer....")
        }

        //initialize
        errorMessageLabel.isHidden = true
        Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil
            {
                self.reset()
                if self.stopThat
                {
                    self.stopThat = false
                    print("UsersID: \(user!.uid)")
                    UsersInformation.currentUsersUID = (user!.uid)
                    self.performSegue(withIdentifier: "toOverview", sender: nil)
                }
            }
        })
    }
    @IBAction func loginButtonDidTouch(_ sender: Any) {
        buttonSoundPlayer.play()
        if emailTextEnter.text != "" && passwordTextEnter.text != ""
        {
            Auth.auth().signIn(withEmail: emailTextEnter.text!, password: passwordTextEnter.text!, completion: {  (user, error) in
                
                if error != nil
                {
                    self.errorMessageLabel.isHidden = false
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        
                        switch errCode {
                        case .invalidEmail:
                            self.errorMessageLabel.text = "Please enter a valid email."
                        case .wrongPassword:
                            self.errorMessageLabel.text = "Inccorrect Password."
                        case .userNotFound:
                            self.errorMessageLabel.text = "User not found!"
                        default:
                            self.errorMessageLabel.text = "Unknown error."
                        }
                    }
                    
                }
                
            })
        }
        else
        {
            errorMessageLabel.isHidden = false
            errorMessageLabel.text = "Please Enter your Email and Password."
        }
    }
    @IBAction func forgotPasswordWasTouched(_ sender: Any) {
        let alert = UIAlertController(title: "Password Reset", message: "Enter your email to reset your password.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Email"
        }
        alert.addAction(UIAlertAction(title: "Send", style: UIAlertActionStyle.default, handler: { (action: UIAlertAction) in
            let textField = alert.textFields![0]
            self.errorMessageLabel.isHidden = false
            if textField.text != ""
            {
                Auth.auth().sendPasswordReset(withEmail: textField.text!, completion: { (Error) in
                    if Error != nil
                    {
                        self.errorMessageLabel.text = "Email could not be sent."
                    }
                    else
                    {
                        self.errorMessageLabel.text = "Password reset sent succesfully."
                    }
                })
            }
            else
            {
                self.errorMessageLabel.text = "Please Enter an Email."
            }
            
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction) in
            alert.dismiss(animated: true, completion: nil)
        }) )
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func SignUpButtonDidTouch(_ sender: Any) {
        buttonSoundPlayer.play()
        performSegue(withIdentifier: "toSignUp", sender: nil)
    }
    func reset()
    {
        errorMessageLabel.isHidden = true
        self.emailTextEnter.text = ""
        self.passwordTextEnter.text = ""
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    

    @IBOutlet var errorMessageLabel: UILabel!
    @IBOutlet var emailTextEnter: UITextField!
    @IBOutlet var passwordTextEnter: UITextField!
    
}
