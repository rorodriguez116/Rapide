//
//  Rapide.swift
//  Rapide
//
//  Created by Rolando Rodriguez on 8/14/20.
//

import Combine
import Foundation

public enum RapideError: Error {
    case unhandledError(Error)
    case missingAuthenticationToken
    case userIsOffline
    case requestError(URLError)
    case expectedErrorWithJSONResponse(data: Data, statusCode: Int)
    case failedToDecodeJSONError
    case invalidHTTPResponse
}

public enum StatusCode: Int, Error, LocalizedError {
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

public class Rapide {
    public typealias QueryItemName = String
    public typealias QueryItemValue = String
    typealias ErrorHandler = (Data, Int) -> Void
    
    public enum Authorization {
        public typealias Token = String
        case none
        case bearer(Token)
    }

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
    
    public enum Scheme: String {
        case https = "https"
        case http = "http"
    }
        
    public static var https: RequestPathBuilder {
        RequestPathBuilder(scheme: .https)
    }
    
    public static var http: RequestPathBuilder {
        RequestPathBuilder(scheme: .http)
    }
    
    public class RequestPathBuilder {
        fileprivate var host: String = ""
        
        fileprivate var path: String = ""
        
        fileprivate var auth = Authorization.none
        
        fileprivate let scheme: Scheme
        
        fileprivate init(scheme: Scheme) {
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
    
    public class RapideExecutor {
        private let requestBuilder: RequestBuilder
        private let pathBuilder: RequestPathBuilder

        fileprivate init(pathBuilder: RequestPathBuilder, requestBuilder: RequestBuilder) {
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
        
        /// Returns a publisher that builds and executes a given HTTP method with a URLRequest configured with the data provider in this builder. The returned publisher has a success type
        ///
        /// - Parameters:
        ///   - method: The HTTP Method to perform for this request.
        ///   - type: The expected Codable conforming result type to map the JSON response to.
        ///   - decoder: A JSON decoder
        ///   - jsonErrorStatusCodes: A series of known HTTP status codes where the service will return a JSON object as response.
        public func execute<T: Decodable>(_ method: HTTPMethod, decoding type: T.Type, decoder: JSONDecoder = JSONDecoder(), jsonErrorStatusCodes: Int?...) -> AnyPublisher<T, RapideError> {
            URLSession(configuration: .default)
                .dataTaskPublisher(for: buildRequest(for: method))
                .mapError({ error -> RapideError in
                    switch error {
                    case URLError.userAuthenticationRequired:
                        return RapideError.missingAuthenticationToken
                        
                    case URLError.notConnectedToInternet:
                        return RapideError.userIsOffline
                                                    
                    default: return RapideError.requestError(error)
                    }
                })
                .validate(using: { data, response in
                    guard let response = response as? HTTPURLResponse else { throw RapideError.invalidHTTPResponse }
                    if jsonErrorStatusCodes.contains(response.statusCode) {
                        throw RapideError.expectedErrorWithJSONResponse(data: data, statusCode: response.statusCode)
                    }
                })
                .map(\.data)
                .decode(type: T.self, decoder: decoder)
                .mapError { error in RapideError.failedToDecodeJSONError }
                .eraseToAnyPublisher()
        }
    }
    
    public class RequestBuilder {
        private let pathBuilder: RequestPathBuilder
        
        fileprivate init(builder: RequestPathBuilder) {
            self.pathBuilder = builder
        }
        
        fileprivate var queryParams = [String: String]()
        
        fileprivate var bodyParams = [String: Any]()
                
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

public struct ResponseProcessor<T: Decodable> {
    public var process: (Data) throws -> T
    
    public init(process: @escaping (Data) throws -> T) {
        self.process = process
    }
}

extension URLComponents {
    mutating func setQueryItems(with parameters: [String: String]) {
        self.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
}

extension Publisher {
    func validate(
        using validator: @escaping (Output) throws -> Void
    ) -> Publishers.TryMap<Self, Output> {
        tryMap { output in
            try validator(output)
            return output
        }
    }
}

extension Publisher {
    func convertToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        self.map(Result.success)
            .catch { Just(.failure($0)) }
            .eraseToAnyPublisher()
    }
}
