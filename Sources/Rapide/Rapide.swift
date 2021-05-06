//
//  APIRequest.swift
//  LaProtectora
//
//  Created by Rolando Rodriguez on 8/14/20.
//  Copyright © 2020 Whiz. All rights reserved.
//

import Combine
import Foundation

public final class Rapide {
    public struct CallResult<T: Codable> {
        public let rawData: [String: Any]
        public let data: T?
    }
    
    public enum CallError: Error {
        case urlError(URLError)
        case networkingError(NetworkError)
        case invalidJSONResponse
        case decodingError(MappingError)
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
    
    public init() {} 
    
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
