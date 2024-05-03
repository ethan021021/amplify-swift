//
//  AuthSignInTokenCredentials.swift
//
//
//  Created by Ethan Thomas on 5/2/24.
//

import Foundation
import AWSPluginsCore

public struct AuthSignInTokenCredentials: AWSTemporaryCredentials {
    public var sessionToken: String
    
    public var expiration: Date
    
    public var accessKeyId: String
    
    public var secretAccessKey: String
    
    
}
