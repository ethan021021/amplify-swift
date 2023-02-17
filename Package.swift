// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Amplify",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "Amplify",
            targets: ["Amplify"]),

        .library(name: "AWSPluginsCore",
                 targets: ["AWSPluginsCore"]),

        .library(name: "AWSAPIPlugin",
                 targets: ["AWSAPIPlugin"]),

        .library(name: "AWSCognitoAuthPlugin",
                 targets: ["AWSCognitoAuthPlugin"]),

        .library(name: "AWSDataStorePlugin",
                 targets: ["AWSDataStorePlugin"]),

        .library(name: "AWSLocationGeoPlugin",
                 targets: ["AWSLocationGeoPlugin"]),

        .library(name: "AWSPinpointAnalyticsPlugin",
                 targets: ["AWSPinpointAnalyticsPlugin"]),

        .library(name: "AWSPredictionsPlugin",
                 targets: ["AWSPredictionsPlugin"]),
        
        .library(name: "CoreMLPredictionsPlugin",
                 targets: ["CoreMLPredictionsPlugin"]),

        .library(name: "AWSS3StoragePlugin",
                 targets: ["AWSS3StoragePlugin"]),

    ],
    dependencies: [
        .package(name: "AWSiOSSDKV2", url: "https://github.com/aws-amplify/aws-sdk-ios-spm.git", .upToNextMinor(from: "2.30.1")),
        .package(name: "AppSyncRealTimeClient", url: "https://github.com/aws-amplify/aws-appsync-realtime-client-ios.git", from: "3.0.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .exact("0.13.2"))
    ],
    targets: [
        .target(
            name: "Amplify",
            path: "Amplify",
            exclude: [
                "Info.plist",
                "Categories/DataStore/Model/Temporal/README.md"
            ]
        ),
        .target(
            name: "AWSPluginsCore",
            dependencies: [.target(name: "Amplify"),
                           .product(name: "AWSCore", package: "AWSiOSSDKV2")],
            path: "AmplifyPlugins/Core/AWSPluginsCore",
            exclude: [
                "Info.plist"
            ]
        ),
        .target(
            name: "AWSAPIPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AppSyncRealTimeClient", package: "AppSyncRealTimeClient")
            ],
            path: "AmplifyPlugins/API/AWSAPICategoryPlugin",
            exclude: [
                "Info.plist",
                "AWSAPIPlugin.md"
            ]
        ),
        .target(
            name: "AWSCognitoAuthPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSAuthCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSMobileClientXCF", package: "AWSiOSSDKV2"),
                .product(name: "AWSCognitoIdentityProvider", package: "AWSiOSSDKV2"),
                .product(name: "AWSCognitoIdentityProviderASF", package: "AWSiOSSDKV2")],
            path: "AmplifyPlugins/Auth/AWSCognitoAuthPlugin",
            exclude: [
                "Resources/Info.plist"
            ]
        ),
        .target(
            name: "AWSDataStorePlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "SQLite", package: "SQLite.swift")],
            path: "AmplifyPlugins/DataStore/AWSDataStoreCategoryPlugin",
            exclude: [
                "Info.plist"
            ]
        ),
        .target(
            name: "AWSLocationGeoPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSLocationXCF", package: "AWSiOSSDKV2")
            ],
            path: "AmplifyPlugins/Geo/AWSLocationGeoPlugin",
            exclude: [
                "Resources/Info.plist"
            ]
        ),
        .target(
            name: "AWSPinpointAnalyticsPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSPinpoint", package: "AWSiOSSDKV2")
            ],
            path: "AmplifyPlugins/Analytics/AWSPinpointAnalyticsPlugin",
            exclude: [
                "Resources/Info.plist"
            ]
        ),
        .target(
            name: "AWSPredictionsPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .target(name: "CoreMLPredictionsPlugin"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSComprehend", package: "AWSiOSSDKV2"),
                .product(name: "AWSPolly", package: "AWSiOSSDKV2"),
                .product(name: "AWSRekognition", package: "AWSiOSSDKV2"),
                .product(name: "AWSTextract", package: "AWSiOSSDKV2"),
                .product(name: "AWSTranscribeStreaming", package: "AWSiOSSDKV2"),
                .product(name: "AWSTranslate", package: "AWSiOSSDKV2")
            ],
            path: "AmplifyPlugins/Predictions/AWSPredictionsPlugin",
            exclude: [
                "Resources/Info.plist"
            ]
        ),
        .target(
            name: "CoreMLPredictionsPlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
            ],
            path: "AmplifyPlugins/Predictions/CoreMLPredictionsPlugin",
            exclude: [
                "Resources/Info.plist"
            ]
        ),
        .target(
            name: "AWSS3StoragePlugin",
            dependencies: [
                .target(name: "Amplify"),
                .target(name: "AWSPluginsCore"),
                .product(name: "AWSCore", package: "AWSiOSSDKV2"),
                .product(name: "AWSS3", package: "AWSiOSSDKV2")
            ],
            path: "AmplifyPlugins/Storage/AWSS3StoragePlugin",
            exclude: [
                "Resources/Info.plist"
            ]
        )
    ]
)
