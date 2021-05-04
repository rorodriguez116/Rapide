//
//  Mapper.swift
//  MyPay
//
//  Created by Rolando Rodriguez on 11/25/20.
//  Copyright © 2020 Rolando Rodriguez. All rights reserved.
//

import Foundation

public protocol Mapper {
    associatedtype T: Codable
        
    func execute(dictionary: [String: Any]) throws ->  T
        
    init()

}
