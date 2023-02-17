//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

@available(iOS 13.0, *)
extension CoreMLPredictionsPlugin {

    public func configure(using configuration: Any?) throws {
        guard configuration is JSONValue else {
            let errorDescription = CoreMLPluginErrorString.decodeConfigurationError.errorDescription
            let recoverySuggestion = CoreMLPluginErrorString.decodeConfigurationError.recoverySuggestion
            throw PluginError.pluginConfigurationError(errorDescription, recoverySuggestion)
        }
        configure(naturalLanguageBehavior: CoreMLNaturalLanguageAdapter(),
                  visionBehavior: CoreMLVisionAdapter(),
                  speechBehavior: CoreMLSpeechAdapter())
    }

    func configure(naturalLanguageBehavior: CoreMLNaturalLanguageBehavior,
                   visionBehavior: CoreMLVisionBehavior,
                   speechBehavior: CoreMLSpeechBehavior,
                   queue: OperationQueue = OperationQueue()) {
        coreMLNaturalLanguage = naturalLanguageBehavior
        coreMLVision = visionBehavior
        coreMLSpeech = speechBehavior
        self.queue = queue
    }
}
