import XCTest
import AsyncXPCConnection

@objc protocol XPCProtocol {
	func noReturnFunction()
}

final class AsyncXPCConnectionTests: XCTestCase {
    func testProtocolInit() throws {
		let conn = NSXPCConnection()
		let remote = RemoteConnection<XPCProtocol>(connection: conn, remoteInterface: XPCProtocol.self)

		XCTAssertTrue(true)
    }
}
