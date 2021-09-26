//
//  RequestPathBuilder.swift
//  
//
//  Created by Rolando Rodriguez on 9/25/21.
//

import Foundation

extension Rapide {
    public class RequestPathBuilder {
        var host: String = ""
        
        var path: String = ""
        
        var auth = Authorization.none
        
        let scheme: Scheme
        
        init(scheme: Scheme) {
            self.scheme = scheme
        }
        
        @discardableResult
        public func host(_ host: String) -> RequestPathBuilder {
            self.host = host
            return self
        }
        
        @discardableResult
        public func path(_ path: String) -> RequestPathBuilder {
            self.path = path
            return self
        }
        
        @discardableResult
        public func authorization(_ auth: Authorization) -> RequestBuilder {
            self.auth = auth
            return RequestBuilder(builder: self)
        }
    }
}
