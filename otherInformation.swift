//
//  otherInformation.swift
//  TradeApp2.0
//
//  Created by Hayden Crabb on 3/26/17.
//  Copyright © 2017 Coconut Productions. All rights reserved.
//

import UIKit

struct UsersInformation
{
    static var currentUsersUID: String = "Y"
    static var currentUsersUsername: String = "X$29384uwalksefR!lsdkfa5%2412"
    static var clickedUsersResources: [String: Int] = [:]
    static var currentUsersResources: [String: Int] = [:]
    static var clickedUsersActiveResources: [String] = []
    static var currentUsersActiveResources: [String] = []
    static var userWeAreTradingWith:String = "The Crabbster"
    static var multiplier:Float = 1.0
    static var settings:[String:Bool] = [:]
    static var individualResourceMultiplier: [String: Float] = [:]
    static var theirIndividualResourceMultiplier: [String: Float] = [:]
    static var adjustTrade: [String : [String:Any]] = [:]
    static var wealthOfCurrentUser: Int = 0
    static var ActivationDate:Int = 0
    static var endDateOfClass:Int = 0
    static var classWeAreIn: String = "Z"
    static var weAreInClass:Bool = false
    static var firstTimeAround:Bool = true
    static var classIsActive:Bool = false
}
