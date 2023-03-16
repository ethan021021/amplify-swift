//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol AuthVerifySoftwareTokenTask: AmplifyAuthTask where Request == AuthVerifySoftwareTokenRequest, Success == AuthAssociateSoftwareTokenResult, Failure == AuthError {}

public extension HubPayload.EventName.Auth {

    /// eventName for HubPayloads emitted by this operation
    static let verifySoftwareTokenAPI = "Auth.verifySoftwareTokenAPI"
}
