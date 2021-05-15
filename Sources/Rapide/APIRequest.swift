//
//  APIRequest.swift
//  
//
//  Created by Rolando Rodriguez on 1/30/21.
//

import Foundation
import Combine

public struct ApiRequest {
    
    public enum HTTPMethod: String {
        case options = "OPTIONS"
        case get     = "GET"
        case head    = "HEAD"
        case post    = "POST"
        case put     = "PUT"
        case patch   = "PATCH"
        case delete  = "DELETE"
        case trace   = "TRACE"
        case connect = "CONNECT"
    }
    
    public enum URLScheme: String {
        case https = "https"
        case http = "http"
    }
    
    public typealias AuthenticationToken = String
    
    public struct Configuration {
        public typealias HostName = String
        
        public typealias HostNameKey = String
        
        public enum Level {
            case simple(HostName)
            case environmentDefined(HostNameKey)
        }
        
        let scheme: URLScheme
        
        let level: Level
        
        let hostname: String
        
        let accessToken: String
        
        public init?(level: Level, scheme: URLScheme, authorization: AuthenticationToken) {
            
            self.scheme = scheme
            
            self.accessToken = authorization
            
            self.level = level
            
            switch level {
            
            case .environmentDefined(let key):
                if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
                   
                    let dictionary = NSDictionary(contentsOfFile: path)
                    
                    guard let hostname = dictionary?[key] as? String else { return nil }
                    
                    self.hostname = hostname
                    
                } else {
                    
                    return nil
                }
                
            case .simple(let hostname): self.hostname = hostname
                
            }
        }
    }
    
    private var path: String = ""
    
    private var version: String = ""
    
    private var resource: String = ""
    
    private var endPoint: String = ""
    
    private var queryParams = [String: String]()
    
    private var bodyParams = [String: Any]()
    
    private var type: HTTPMethod = .get
    
    private var configuration: Configuration?
    
    private init() {  }
    
    private func url() -> URL? {
        guard let configuration = self.configuration else { return nil }
        
        var urlComponents = URLComponents()
        
        urlComponents.scheme = configuration.scheme.rawValue
        
        urlComponents.host = configuration.hostname
        
        urlComponents.path = path + resource + endPoint
        
        if !queryParams.isEmpty {
            urlComponents.setQueryItems(with: queryParams)
        }
        
        return urlComponents.url
    }

    private var contentType: String {
        "application/json"
    }
    
    public class Builder {
        
        public enum BuilderError: Error {
            case invalidURLCannotParseIntoURLRequest
        }
        
        private var request = ApiRequest()
        private var configuration: ApiRequest.Configuration?
        private var configurationLevel: ApiRequest.Configuration.Level?
        
        public init() { }
        
        func getConfiguration() -> ApiRequest.Configuration? {
            return configuration
        }
                
        @discardableResult
        public func withConfiguration(_ config: Configuration?) -> ApiRequest.Builder {
            self.configuration = config
            self.request.configuration = config
            return self
        }
        
        @discardableResult
        public func withPath(_ path: String) -> ApiRequest.Builder {
            self.request.path = path
            return self
        }
        
        @discardableResult
        public func withVersion(_ version: String) -> ApiRequest.Builder {
            self.request.version = version
            return self
        }
        
        @discardableResult
        public func withResource(_ resource: String) -> ApiRequest.Builder {
            self.request.resource = resource
            return self
        }
        
        @discardableResult
        public func withEndPoint(_ endPoint: String) -> ApiRequest.Builder {
            self.request.endPoint = endPoint
            return self
        }
        
        @discardableResult
        public func withBodyParams(_ params: [String: Any]) -> ApiRequest.Builder {
            self.request.bodyParams = params
            return self
        }
        
        @discardableResult
        public func withType(_ type: HTTPMethod) -> ApiRequest.Builder {
            self.request.type = type
            return self
        }
        
        @discardableResult
        public func withQueryParams(_ params: [String: String]) -> ApiRequest.Builder {
            self.request.queryParams = params
            return self
        }
        
        public func buildPublisher() -> AnyPublisher<URLRequest, Error> {
            Future<URLRequest, Error> { [weak self] promise in
                do {
                    guard let urlRequest = try self?.build() else { promise(.failure( BuilderError.invalidURLCannotParseIntoURLRequest)); return  }
                    
                    promise(.success(urlRequest))
                } catch {
                    promise(.failure(error))
                }
                
            }
            .eraseToAnyPublisher()
        }

        
        public func build() throws -> URLRequest {
            guard let configuration = self.request.configuration, let url = self.request.url() else { throw BuilderError.invalidURLCannotParseIntoURLRequest }
            
            var urlRequest = URLRequest(url: url)
            
            urlRequest.httpMethod = self.request.type.rawValue
            
            urlRequest.setValue(self.request.contentType, forHTTPHeaderField: "Content-Type")
            
            urlRequest.setValue(self.request.contentType, forHTTPHeaderField: "Accept")
            
            urlRequest.setValue("Bearer \(configuration.accessToken)", forHTTPHeaderField: "Authorization")
            
            if !self.request.bodyParams.isEmpty {
                urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: self.request.bodyParams, options: [])
            }
            return urlRequest
        }
    }
}

extension URLComponents {
    mutating func setQueryItems(with parameters: [String: String]) {
        self.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
}
