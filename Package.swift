// swift-tools-version: 5.8
import PackageDescription

let package = Package(
	name: "AsyncXPCConnection",
	platforms: [
		.macOS(.v10_15),
		.macCatalyst(.v13),
		.iOS(.v13),
		.tvOS(.v13),
		.watchOS(.v6),
	],
	products: [
		.library(name: "AsyncXPCConnection", targets: ["AsyncXPCConnection"]),
	],
	targets: [
		.target(name: "AsyncXPCConnection"),
		.testTarget(name: "AsyncXPCConnectionTests", dependencies: ["AsyncXPCConnection"]),
	]
)

let swiftSettings: [SwiftSetting] = [
	.enableExperimentalFeature("StrictConcurrency")
]

for target in package.targets {
	var settings = target.swiftSettings ?? []
	settings.append(contentsOf: swiftSettings)
	target.swiftSettings = settings
}
