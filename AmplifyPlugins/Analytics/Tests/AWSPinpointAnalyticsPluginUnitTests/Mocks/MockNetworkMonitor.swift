//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
@_spi(NetworkMonitor) import Amplify
import Foundation

class MockNetworkMonitor: NetworkMonitor {
    var isOnline = true
    func startMonitoring(using queue: DispatchQueue) {}
    func stopMonitoring() {}
}
