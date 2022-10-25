//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Amplify
@testable import AWSLocationGeoPlugin
import CoreLocation

public class MockAWSDeviceTracker: AWSDeviceTracker {
    
    // MARK: - Method call counts for MockAWSDeviceTracker
    var configureCalled = 0
    var startDeviceTrackingCalled = 0
    var stopDeviceTrackingCalled = 0
    
    public override func configure(with options: Geo.LocationManager.TrackingSessionOptions) {
        configureCalled += 1
        super.configure(with: options)
    }
    
    public override func configureLocationManager(with options: Geo.LocationManager.TrackingSessionOptions) {
        // do nothing
    }
    
    public override func startTracking() {
        startDeviceTrackingCalled += 1
        super.startTracking()
    }
    
    public override func stopTracking() {
        stopDeviceTrackingCalled += 1
        super.stopTracking()
    }
   
}
