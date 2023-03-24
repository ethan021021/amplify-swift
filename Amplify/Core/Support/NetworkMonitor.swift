//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Network

@_spi(NetworkMonitor)
public protocol NetworkMonitor: AnyObject {
    var isOnline: Bool { get }
    func startMonitoring(using queue: DispatchQueue)
    func stopMonitoring()
}

@_spi(NetworkMonitor)
extension NWPathMonitor: NetworkMonitor {
    public var isOnline: Bool {
        currentPath.status == .satisfied
    }
    
    public func startMonitoring(using queue: DispatchQueue) {
        start(queue: queue)
    }
    
    public func stopMonitoring() {
        cancel()
    }
}
