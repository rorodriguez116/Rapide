//
//  Mapper.swift
//  Rapide
//
//  Created by Rolando Rodriguez on 11/25/20.
//

import Foundation

public protocol Mapper {
    associatedtype T: Codable
        
    func execute(dictionary: [String: Any]) throws ->  T
        
    init()

}
