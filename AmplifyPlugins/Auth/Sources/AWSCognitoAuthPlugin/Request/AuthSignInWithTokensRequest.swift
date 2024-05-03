//
//  AuthSignInWithTokensRequest.swift
//
//
//  Created by Ethan Thomas on 4/24/24.
//

import Amplify
import Foundation

public struct AuthSignInWithTokensRequest: AmplifyOperationRequest {
    public let idToken: String
    
    public let accessToken: String
    
    public let refreshToken: String
    
    public let expiresIn: Int?
    
    public var options: Options
    
    init(idToken: String, accessToken: String, refreshToken: String, expiresIn: Int?) {
        self.idToken = idToken
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.options = Options()
    }
}
public extension AuthSignInWithTokensRequest {
    struct Options {
        public init() {}
    }
}
