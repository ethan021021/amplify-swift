//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore
//import AWSCore

@available(iOS 13.0, *)
extension AWSPredictionsPlugin {

    /// Configures AWSPredictionsPlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow. Retrieves region, and
    /// default configuration values to allow overrides on plugin API calls.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - PluginError.pluginConfigurationError: If one of the configuration values is invalid or empty
    public func configure(using configuration: Any?) throws {

        guard let jsonValueConfiguration = configuration as? JSONValue else {
            throw PluginError.pluginConfigurationError(PluginErrorMessage.decodeConfigurationError.errorDescription,
                                                       PluginErrorMessage.decodeConfigurationError.recoverySuggestion)
        }

        let configurationData =  try JSONEncoder().encode(jsonValueConfiguration)
        let predictionsConfiguration = try JSONDecoder().decode(PredictionsPluginConfiguration.self,
                                                                from: configurationData)
        let authService = AWSAuthService()
        let credentialsProvider = authService.getCredentialsProvider()
        let coremlService = try CoreMLPredictionService(configuration: configuration)
        let predictionsService = try AWSPredictionsService(configuration: predictionsConfiguration,
                                                           credentialsProvider: credentialsProvider,
                                                           identifier: key)
        configure(predictionsService: predictionsService,
                  coreMLSerivce: coremlService,
                  authService: authService,
                  config: predictionsConfiguration)
    }

    func configure(predictionsService: AWSPredictionsService,
                   coreMLSerivce: CoreMLPredictionBehavior,
                   authService: AWSAuthServiceBehavior,
                   config: PredictionsPluginConfiguration,
                   queue: OperationQueue = OperationQueue()) {
        self.predictionsService = predictionsService
        coreMLService = coreMLSerivce
        self.authService = authService
        self.config = config
        self.queue = queue
    }
}
