//
//  Int+random.swift
//  swiftdemo
//
//  Created by Emiel Lensink on 04/10/2017.
//  Copyright © 2017 Emiel Lensink. All rights reserved.
//

import Foundation

infix operator <>: AdditionPrecedence

extension Int {
	
	static func <> (left: Int, right: Int) -> Int {
		let range = right - left
		let randomInRange = Int(arc4random()) % range
		
		return randomInRange + left
	}
	
}
