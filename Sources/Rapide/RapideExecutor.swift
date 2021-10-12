//
//  RapideExecutor.swift
//  
//
//  Created by Rolando Rodriguez on 9/25/21.
//

import Foundation
import Combine

extension Rapide {
    public struct RapideExecutor {
        private let requestBuilder: RequestBuilder
        private let pathBuilder: RequestPathBuilder

        init(pathBuilder: RequestPathBuilder, requestBuilder: RequestBuilder) {
            self.requestBuilder = requestBuilder
            self.pathBuilder = pathBuilder
        }
        
        private func url() -> URL? {
            var urlComponents = URLComponents()
            
            urlComponents.scheme = pathBuilder.scheme.rawValue
            
            urlComponents.host = pathBuilder.host
            
            urlComponents.path = pathBuilder.path
            
            if !requestBuilder.queryParams.isEmpty {
                urlComponents.setQueryItems(with: requestBuilder.queryParams)
            }
            
            return urlComponents.url
        }
        
        private var contentType: String {
            "application/json"
        }

        fileprivate func buildRequest(for method: HTTPMethod) -> URLRequest {
            guard let url = url() else { fatalError("\(Self.self): Cannot build a URLRequest with an ill defined base url.") }
            var urlRequest = URLRequest(url: url)
            
            urlRequest.httpMethod = method.rawValue
            
            urlRequest.setValue(self.contentType, forHTTPHeaderField: "Content-Type")
            
            urlRequest.setValue(self.contentType, forHTTPHeaderField: "Accept")
            
            if case let Authorization.bearer(token) = pathBuilder.auth {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            if !self.requestBuilder.bodyParams.isEmpty {
                urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: self.requestBuilder.bodyParams, options: [])
            }
            
            return urlRequest
        }
        
        private func printDebugInfo(from data: Data, request: URLRequest, params: [String: Any], response: HTTPURLResponse) {
            print("--------RAPIDE DEBUGGING--------")
            if let url = response.url {
                print("Path: \(url)")
            }
            
            if let data = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted), let jsonParams = String(data: data, encoding: String.Encoding.utf8)  {
                print("Parameters: \(jsonParams)")
            }
            
            
            print("Result: HTTP Status Code \(response.statusCode) \(StatusCode(rawValue: response.statusCode) ?? StatusCode.invalidData)")
            
            if let json = String(data: data, encoding: String.Encoding.utf8) {
                print("Response: \(json)")
            }
            
            print("--------------------------------")
        }
                
        /// Returns a publisher that builds and executes a given HTTP method with a URLRequest configured with the data provider in this builder. The returned publisher has a success type
        ///
        /// - Parameters:
        ///   - method: The HTTP Method to perform for this request.
        ///   - type: The expected Codable conforming result type to map the JSON response to.
        ///   - decoder: A JSON decoder
        ///   - customErrorType: A known error model type where the service will return a JSON object as an error response.
        ///
        public func execute<T: Decodable>(_ method: HTTPMethod, decoding type: T.Type, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<T, Error> {
            let request = buildRequest(for: method)
            return URLSession(configuration: .default)
                .dataTaskPublisher(for: request)
                .validate { data, response in
                    guard let response = response as? HTTPURLResponse else { throw RapideError.invalidHTTPResponse }
                    printDebugInfo(from: data, request: request, params: requestBuilder.bodyParams, response: response)
                }
                .map(\.data)
                .decode(type: T.self, decoder: decoder)
                .eraseToAnyPublisher()
        }
        
        /// Returns a publisher that builds and executes a given HTTP method with a URLRequest configured with the data provider in this builder. The returned publisher has a success type
        ///
        /// - Parameters:
        ///   - method: The HTTP Method to perform for this request.
        ///   - type: The expected Codable conforming result type to map the JSON response to.
        ///   - decoder: A JSON decoder
        ///   - customErrorType: A known error model type where the service will return a JSON object as an error response. Only valid for status codes 400 and 500 responses.
        ///
        public func execute<T: Decodable, E: DecodableError>(_ method: HTTPMethod, decoding type: T.Type, decoder: JSONDecoder = JSONDecoder(), customErrorType: E.Type) -> AnyPublisher<T, Error> {
            let request = buildRequest(for: method)
            return URLSession(configuration: .default)
                .dataTaskPublisher(for: request)
                .validate { data, response in
                    guard let response = response as? HTTPURLResponse else { throw RapideError.invalidHTTPResponse }
                    printDebugInfo(from: data, request: request, params: requestBuilder.bodyParams, response: response)
                    
                    let stringStatusCode = String(response.statusCode)
                    
                    if stringStatusCode.hasPrefix("4") || stringStatusCode.hasPrefix("5") {
                        let errorModel = try decoder.decode(customErrorType, from: data)
                        
                        throw errorModel
                    }
                }
                .map(\.data)
                .decode(type: T.self, decoder: decoder)
                .eraseToAnyPublisher()
        }
        
        /// Returns a publisher that builds and executes a given HTTP method with a URLRequest configured with the data provider in this builder. The returned publisher has a success type [String: Any]
        ///
        /// - Parameters:
        ///   - method: The HTTP Method to perform for this request.
        public func execute(_ method: HTTPMethod) -> AnyPublisher<[String: Any], Error> {
            let request = buildRequest(for: method)
            return URLSession(configuration: .default)
                .dataTaskPublisher(for: request)
                .validate { data, response in
                    guard let response = response as? HTTPURLResponse else { throw RapideError.invalidHTTPResponse }
                    printDebugInfo(from: data, request: request, params: requestBuilder.bodyParams, response: response)
                }
                .map(\.data)
                .tryMap({ data in
                    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] else { throw RapideError.invalidHTTPResponse }
                    return dictionary
                })
                .eraseToAnyPublisher()
        }
        
        /// Returns a publisher that builds and executes a given HTTP method with a URLRequest configured with the data provider in this builder. The returned publisher has a success type [String: Any]
        ///
        /// - Parameters:
        ///   - method: The HTTP Method to perform for this request.
        ///   - type: The expected Codable conforming result type to map the JSON response to.
        ///   - decoder: A JSON decoder
        ///   - customErrorType: A known error model type where the service will return a JSON object as an error response. Only valid for status codes 400 and 500 responses.
        ///
        public func execute<E: DecodableError>(_ method: HTTPMethod, customErrorType: E.Type, decoder: JSONDecoder = JSONDecoder()) -> AnyPublisher<[String: Any], Error> {
            let request = buildRequest(for: method)
            return URLSession(configuration: .default)
                .dataTaskPublisher(for: request)
                .validate { data, response in
                    guard let response = response as? HTTPURLResponse else { throw RapideError.invalidHTTPResponse }
                    printDebugInfo(from: data, request: request, params: requestBuilder.bodyParams, response: response)
                
                    let stringStatusCode = String(response.statusCode)
                
                    if stringStatusCode.hasPrefix("4") || stringStatusCode.hasPrefix("5") {
                        let errorModel = try decoder.decode(customErrorType, from: data)
                        
                        throw RapideError.customError(errorModel)
                    }
                }
                .map(\.data)
                .tryMap({ data in
                    guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:Any] else { throw RapideError.invalidHTTPResponse }
                    return dictionary
                })
                .eraseToAnyPublisher()
        }
    }
}

