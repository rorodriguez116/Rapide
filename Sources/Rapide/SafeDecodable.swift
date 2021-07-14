//
//  SafeDecodable.swift
//  Rapide
//
//  Created by Rolando Rodriguez on 5/31/21.
//

import Foundation

/// Wraps a decodable type that might fail decoding.
///
/// Use this type to avoid total decoding failure of an array of decodable(s) when only a single or a few items fail decoding.
struct SafeDecodable<T: Decodable>: Decodable {
    let result: Result<T, Error>
    
    init(from decoder: Decoder) throws {
        result = Result(catching: { try T(from: decoder) })
    }
}
