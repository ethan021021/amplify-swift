//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct VerifySoftwareTokenSetup: Action {

    var identifier: String = "VerifySoftwareTokenSetup"

    let associateSoftwareTokenData: AssociateSoftwareTokenData
    let verifySoftwareTokenUserCode: String

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)

        do {
            let userpoolEnv = try environment.userPoolEnvironment()
            let client = try userpoolEnv.cognitoUserPoolFactory()
            let input = VerifySoftwareTokenInput(
                session: associateSoftwareTokenData.session,
                userCode: verifySoftwareTokenUserCode)
            let result = try await client.verifySoftwareToken(input: input)

            guard let session = result.session else {
                throw SignInError.unknown(message: "Unable to retrieve the session value from VerifySoftwareToken response")
            }

            let responseEvent = SetupSoftwareTokenEvent(eventType:
                    .respondToAuthChallenge(session))
            logVerbose("\(#fileID) Sending event \(responseEvent)",
                       environment: environment)
            await dispatcher.send(responseEvent)
        } catch let error as SignInError {
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        } catch {
            let error = SignInError.service(error: error)
            let errorEvent = SignInEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        }
    }

}

extension VerifySoftwareTokenSetup: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension VerifySoftwareTokenSetup: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
