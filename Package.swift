// swift-tools-version: 5.5
import PackageDescription

let package = Package(
	name: "AsyncXPCConnection",
	platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
	products: [
		.library(name: "AsyncXPCConnection", targets: ["AsyncXPCConnection"]),
	],
	targets: [
		.target(name: "AsyncXPCConnection"),
		.testTarget(name: "AsyncXPCConnectionTests", dependencies: ["AsyncXPCConnection"]),
	]
)
