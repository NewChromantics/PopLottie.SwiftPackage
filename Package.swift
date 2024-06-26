// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription



let package = Package(
	name: "PopLottie",
	
	platforms: [
		.iOS(.v15),
		.macOS(.v12)
	],
	

	products: [
		.library(
			name: "PopLottie",
			targets: [
				"PopLottie"
			]),
	],
	targets: [

		.target(
			name: "PopLottie",
			path: "./PopLottieSwift"
		)
	]
)
