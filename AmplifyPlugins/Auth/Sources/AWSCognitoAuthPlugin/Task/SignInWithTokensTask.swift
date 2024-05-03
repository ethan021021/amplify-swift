//
//  SignInWithTokensTask.swift
//
//
//  Created by Ethan Thomas on 4/24/24.
//

import Foundation
import Amplify

protocol AuthSignInWithTokensTask: AmplifyAuthTask where Request == AuthSignInWithTokensRequest,
                                                               Success == AuthSignInResult,
                                                               Failure == AuthError {}

public extension HubPayload.EventName.Auth {
    static let signedInWithTokens = "Auth.signedInWithTokens"
}

public class SignInWithTokensTask: AuthSignInWithTokensTask, DefaultLogger {
    private let request: AuthSignInWithTokensRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    
    init(_ request: AuthSignInWithTokensRequest, authStateMachine: AuthStateMachine, taskHelper: AWSAuthTaskHelper) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.taskHelper = taskHelper
    }
    
    public var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signedInWithTokens
    }
    
    func execute() async throws -> AuthSignInResult {
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()
        let state = await authStateMachine.currentState
        guard case .configured(let authNState, let authZState) = state  else {
            throw AuthError.invalidState(
                "Sign in with tokens could not be completed.",
                AuthPluginErrorConstants.invalidStateError, nil)
        }

        if isValidAuthNStateToStart(authNState) && isValidAuthZStateToStart(authZState) {
            return try await startSigningInWithTokens()
        } else {
            throw AuthError.invalidState(
                "Sign in with tokens could not be completed.",
                AuthPluginErrorConstants.invalidStateError, nil)
        }
    }
    
    func isValidAuthNStateToStart(_ authNState: AuthenticationState) -> Bool {
        switch authNState {
        case .notConfigured, .signedOut, .federatedToIdentityPool, .error:
            return true
        default:
            return false
        }
    }

    func isValidAuthZStateToStart(_ authZState: AuthorizationState) -> Bool {
        switch authZState {
        case .configured, .sessionEstablished, .error:
            return true
        default:
            return false
        }
    }
    
    func startSigningInWithTokens() async throws -> AuthSignInResult {
        await sendStartSigningInWithTokensEvent()
        let stateSequences = await authStateMachine.listen()
        log.verbose("Waiting for sign in with tokens to complete")
        for await state in stateSequences {
            guard  case .configured(let authNState, let authZState) = state else {
                continue
            }

            switch (authNState, authZState) {
            case (.signedInWithTokens(_), .sessionEstablished(let credentials)):
                return try getSignInWithTokensResult(credentials)
            case (.error, .error(let authZError)):
                throw authZError.authError
            default:
                continue
            }
        }
        throw AuthError.unknown("Could not start sign in with tokens. The previous credentials have been retained")
    }
    
    func sendStartSigningInWithTokensEvent() async {
        let userPoolTokens = AWSCognitoUserPoolTokens(idToken: request.idToken,
                                                      accessToken: request.accessToken,
                                                      refreshToken: request.refreshToken,
                                                      expiresIn: request.expiresIn)
        let signedInData = SignedInData(signedInDate: Date(),
                                        signInMethod: .apiBased(.userSRP),
                                        deviceMetadata: .metadata(.init(deviceKey: "", deviceGroupKey: "")),
                                        cognitoUserPoolTokens: userPoolTokens)
        let event = AuthenticationEvent(eventType: .initializedSignInWithTokens(signedInData))
        await authStateMachine.send(event)
    }
    
    private func getSignInWithTokensResult(_ result: AmplifyCredentials)
    throws -> AuthSignInResult {
        switch result {
        case .userPoolAndIdentityPool(_, _, _):
            return AuthSignInResult(nextStep: .done)
        default:
            throw AuthError.unknown("Unable to parse credentials to expected output", nil)
        }
    }
}
