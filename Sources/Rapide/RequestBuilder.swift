//
//  RequestBuilder.swift
//  
//
//  Created by Rolando Rodriguez on 9/25/21.
//

import Foundation

extension Rapide {
    public class RequestBuilder {
        private let pathBuilder: RequestPathBuilder
        
        init(builder: RequestPathBuilder) {
            self.pathBuilder = builder
        }
        
        var queryParams = [String: String]()
        
        var bodyParams = [String: Any]()
                
        @discardableResult
        public func params(_ params: [String: Any]) -> RapideExecutor {
            self.bodyParams = params
            return RapideExecutor(pathBuilder: pathBuilder, requestBuilder: self)
        }
        
        @discardableResult
        public func query(_ params: [QueryItemName: QueryItemValue]) -> RapideExecutor {
            self.queryParams = params
            return RapideExecutor(pathBuilder: pathBuilder, requestBuilder: self)
        }
    }
}
