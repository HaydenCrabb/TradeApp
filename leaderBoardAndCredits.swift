//
//  leaderBoardAndCredits.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 7/27/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class leaderboardAndCredits:UIViewController, UITableViewDelegate, UITableViewDataSource
{
    var Students: [String] = []
    var Wealths: [Int] = []
    var StudentsAndWealths: [String: Int] = [:]
    var backTickSoundPlayer:AVAudioPlayer = AVAudioPlayer()
    var leaderboard:Bool = true
    
    override func viewDidLoad() {
        let backTickPath = Bundle.main.path(forResource: "backTick.mp3", ofType: nil)!
        let backTickSound = NSURL(fileURLWithPath: backTickPath)
        do {
            try backTickSoundPlayer = AVAudioPlayer(contentsOf: backTickSound as URL)
            backTickSoundPlayer.prepareToPlay()
        } catch {
        }

        mainTableView.layer.cornerRadius = 10
        mainTableView.layer.masksToBounds = true
        mainTableView.allowsSelection = false
        if leaderboard
        {
            for outlet in creditOutlets
            {
                outlet.isHidden = true
            }
            Database.database().reference(withPath: UsersInformation.classWeAreIn).child("NamesOfUsers").observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists()
                {
                    let allData = snapshot.value as! [String:[String:Int]]
                    for user in allData
                    {
                        let tempDict = user.value
                        self.StudentsAndWealths[user.key] = tempDict["Wealth"]
                        self.Wealths.append(tempDict["Wealth"]!)
                    }
                    self.Wealths = self.quicksort(list: self.Wealths)
                    self.matchUsersAndWealths()
                    self.mainTableView.reloadData()
                }
                
            })
            

        }
        else
        {
            mainTableView.isHidden = true
            titleOutlet.text = "Credits"
        }
    }
    func matchUsersAndWealths()
    {
        var i = 0
        while StudentsAndWealths.count != 0 {
            for data in StudentsAndWealths
            {
                if data.value == Wealths[i]
                {
                    Students.append(data.key)
                    StudentsAndWealths[data.key] = nil
                    i = i + 1
                }
            }
        }
    }
    func quicksort(list:[Int]) -> [Int] {
        if list.count == 0 {
            return []
        }
        
        let pivotValue = list[0]
        let listStripped = list.count > 1 ? list[1...list.count - 1] : []
        let smaller: [Int] = listStripped.filter{$0 >= pivotValue}
        let greater: [Int] = listStripped.filter{$0 < pivotValue}
        
        return quicksort(list: smaller) + Array(arrayLiteral:pivotValue) + quicksort(list: greater)
    }
    
    
    
    @IBAction func backButtonWasPressed(_ sender: Any) {
        backTickSoundPlayer.play()
        self.performSegue(withIdentifier: "creditsToMain", sender: nil)
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return Students.count
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let myCell = mainTableView.dequeueReusableCell(withIdentifier: "NamedCell", for: indexPath) as! LeaderboardTableViewCell
        if Students[indexPath.row] == UsersInformation.currentUsersUsername
        {
            myCell.backgroundColor = UIColor(displayP3Red: 0.29, green: 0.6, blue: 0.34, alpha: 0.7)
        }
        myCell.nameLabel.text = "\(indexPath.row + 1). \(Students[indexPath.row])"
        myCell.wealthLabel.text = "$\(Wealths[indexPath.row])"
        return myCell
    }
    
    
    @IBOutlet var creditOutlets: [UILabel]!
    
    @IBOutlet var titleOutlet: UILabel!
    @IBOutlet var mainTableView: UITableView!
    
}
