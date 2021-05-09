//
//  APIRequest.swift
//  LaProtectora
//
//  Created by Rolando Rodriguez on 8/14/20.
//  Copyright © 2020 Whiz. All rights reserved.
//

import Combine
import Foundation

internal protocol NetworkProvider {
    func call(request: URLRequest) -> AnyPublisher<[String: Any], Error>
    func call<T: Decodable>(request: URLRequest, decodable: T.Type) -> AnyPublisher<T, Error>
}

extension NetworkProvider {
    public func call(request: URLRequest) -> AnyPublisher<[String: Any], Error> {
        URLSession(configuration: .default).dataTaskPublisher(for: request)
            .mapError({ (error) -> CallError in
                CallError.urlError(error)
            })
            .tryMap { (data, response) in
                guard
                    let response = response as? HTTPURLResponse
                else { throw CallError.networkingError(.noResponse) }
                
                if response.statusCode == 200 {
                    if let responseDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        return responseDict
                    }
                    
                    throw CallError.invalidJSONResponse
                }
                
                throw CallError.networkingError(NetworkError(rawValue: response.statusCode) ?? NetworkError.noResponse)
            }
            .eraseToAnyPublisher()
    }
    
    public func call<T: Decodable>(request: URLRequest, decodable: T.Type) -> AnyPublisher<T, Error> {
        URLSession(configuration: .default).dataTaskPublisher(for: request)
            .mapError({ (error) -> CallError in
                CallError.urlError(error)
            })
            .tryMap { (data, response) in
                guard
                    let response = response as? HTTPURLResponse
                else { throw CallError.networkingError(.noResponse) }
                
                if response.statusCode == 200 {
                    let decoder = JSONDecoder()
                    let JSON = try decoder.decode(decodable, from: data)
                    return JSON
                } else {
                    throw CallError.networkingError(NetworkError(rawValue: response.statusCode) ?? NetworkError.noResponse)
                }
            }
            .eraseToAnyPublisher()
    }
}

public enum CallError: Error {
    case urlError(URLError)
    case networkingError(NetworkError)
    case invalidJSONResponse
    case decodingError(MappingError)
    case failedToDecodeJSONError(URLSession.DataTaskPublisher.Output)
}

public enum NetworkError: Int, Error, LocalizedError {
    case invalidData = 0
    case noResponse = 1
    case Continue = 100
    case SwitchingProtocols = 101
    case Processing = 102
    
    case OK = 200
    case Created = 201
    case Accepted = 202
    case NonauthoritativeInformation = 203
    case NoContent = 204
    case ResetContent = 205
    case PartialContent = 206
    case MultiStatus = 207
    case AlreadyReported = 208
    case IMUsed = 226
    
    case MultipleChoices = 300
    case MovedPermanently = 301
    case Found = 302
    case SeeOther = 303
    case NotModified = 304
    case UseProxy = 305
    case TemporaryRedirect = 307
    case PermanentRedirect = 308
    
    case BadRequest = 400
    case Unauthorized = 401
    case PaymentRequired = 402
    case Forbidden = 403
    case NotFound = 404
    case MethodNotAllowed = 405
    case NotAcceptable = 406
    case ProxyAuthenticationRequired = 407
    case RequestTimeout = 408
    case Conflict = 409
    case Gone = 410
    case LengthRequired = 411
    case PreconditionFailed = 412
    case PayloadTooLarge = 413
    case RequestURITooLong = 414
    case UnsupportedMediaType = 415
    case RequestedRangeNotSatisfiable = 416
    case ExpectationFailed = 417
    case ImAteapot = 418
    case MisdirectedRequest = 421
    case UnprocessableEntity = 422
    case Locked = 423
    case FailedDependency = 424
    case UpgradeRequired = 426
    case PreconditionRequired = 428
    case TooManyRequests = 429
    case RequestHeaderFieldsTooLarge = 431
    case ConnectionClosedWithoutResponse = 444
    case UnavailableForLegalReasons = 451
    case ClientClosedRequest = 499
    
    case InternalServerError = 500
    case NotImplemented = 501
    case BadGateway = 502
    case ServiceUnavailable = 503
    case GatewayTimeout = 504
    case HTTPVersionNotSupported = 505
    case VariantAlsoNegotiates = 506
    case InsufficientStorage = 507
    case LoopDetected = 508
    case NotExtended = 510
    case NetworkAuthenticationRequired = 511
    case NetworkConnectTimeoutError = 599
}

public enum MappingError: Error, LocalizedError {
    case couldNotUnwrapData
    case mapperResultTypeDoestNotMatchIntendedResultType
}

public class Rapide: NetworkProvider {
    
    public init() {}
    
    private static var configuration: ApiRequest.Configuration?
    
    /// Configures the shared instance of Rapide. Used to perform tasks when using the same scheme and domain.
    public static func configure(level: ApiRequest.Configuration.Level, scheme: ApiRequest.URLScheme) {
        self.configuration = ApiRequest.Configuration(level: level, scheme: scheme, authorization: "")
    }
    
    public static var main: Rapide.Lighthing {
        guard let config = configuration else { fatalError("Rapide: Can't access main without first providing a configuration. Use Rapide.configure() first.") }
        return Rapide.Lighthing.newProvider(with: config)
    }
    
    public struct Lighthing: NetworkProvider {
        static func newProvider(with config: ApiRequest.Configuration) -> Lighthing {
            Lighthing(config: config)
        }
        
        private init(config: ApiRequest.Configuration) {
            self.configuration = config
        }
        
        private let builder = ApiRequest.Builder()
        private var configuration: ApiRequest.Configuration
        private var configurationLevel: ApiRequest.Configuration.Level?
        
        @discardableResult
        public func withPath(_ path: String) -> Rapide.Lighthing {
            self.builder.withPath(path)
            return self
        }
        
        @discardableResult
        public func withVersion(_ version: String) -> Rapide.Lighthing {
            self.builder.withVersion(version)
            return self
        }
        
        @discardableResult
        public func withResource(_ resource: String) -> Rapide.Lighthing {
            self.builder.withResource(resource)
            return self
        }
        
        @discardableResult
        public func withEndPoint(_ endPoint: String) -> Rapide.Lighthing {
            self.builder.withEndPoint(endPoint)
            return self
        }
        
        @discardableResult
        public func withBodyParams(_ params: [String: Any]) -> Rapide.Lighthing {
            self.builder.withBodyParams(params)
            return self
        }
        
        @discardableResult
        public func withQueryParams(_ params: [String: String]) -> Rapide.Lighthing {
            self.builder.withQueryParams(params)
            return self
        }
        
        @discardableResult
        public mutating func withAuthorization(_ authorization: String) -> Rapide.Lighthing {
            guard
                let newConfiguration =
                    ApiRequest.Configuration(
                        level: configuration.level,
                        scheme: configuration.scheme,
                        authorization: authorization)
            else { fatalError("Rapide: Can't perform request without first providing a configuration.") }
            
            self.configuration = newConfiguration
            self.builder.withConfiguration(newConfiguration)
            return self
        }
        
        public func request<T: Decodable>(_ method: ApiRequest.HTTPMethod, expect decodable: T.Type) -> AnyPublisher<T, Error> {
            builder.withType(method)
            return
                builder
                .buildPublisher()
                .flatMap { self.call(request: $0, decodable: decodable) }
                .eraseToAnyPublisher()
        }
        
    }
}

public struct ResponseProcessor<T: Decodable> {
    var process: (Data) throws -> T
}

extension Rapide.Lighthing {
    public func call<T: Decodable>(request: URLRequest, processor: ResponseProcessor<T>) -> AnyPublisher<T, Error> {
        URLSession(configuration: .default).dataTaskPublisher(for: request)
            .mapError({ (error) -> CallError in
                CallError.urlError(error)
            })
            .tryMap({ output in
                guard
                    let response = output.response as? HTTPURLResponse
                else { throw CallError.failedToDecodeJSONError(output) }
                
                if response.statusCode == 200 {
                    return try processor.process(output.data)
                } else {
                    throw CallError.networkingError(NetworkError(rawValue: response.statusCode) ?? NetworkError.noResponse)
                }
                
            })
            .eraseToAnyPublisher()
    }
    
    public func request<T: Decodable>(_ method: ApiRequest.HTTPMethod, processor: ResponseProcessor<T>) -> AnyPublisher<T, Error> {
        builder.withType(method)
        return
            builder
            .buildPublisher()
            .flatMap { self.call(request: $0, processor: processor) }
            .eraseToAnyPublisher()
    }
}
