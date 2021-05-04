//
//  Codable+Extensions.swift
//  
//
//  Created by Rolando Rodriguez on 1/30/21.
//

import Foundation

public extension Encodable {
    /// Returns a JSON dictionary, with choice of minimal information
    
    func dictionary() -> [String: Any]? {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else { return nil }
        do {
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] else {return nil}
            return dictionary
        }
        catch (let error) { print(error.localizedDescription); return nil}
    }
}

public extension Decodable {
    /// Initialize from JSON Dictionary. Return nil on failure
    init?(dictionary value: [String:Any]){
        guard JSONSerialization.isValidJSONObject(value) else { print("\(#function) Invalid JSON format while trying to initialize \(Self.self)"); return nil }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: [])
            let newValue = try JSONDecoder().decode(Self.self, from: jsonData)
            self = newValue
        } catch let error {
            print("Invalid JSON format while trying to initialize \(Self.self)", error)
            return nil
        }
    }
}
