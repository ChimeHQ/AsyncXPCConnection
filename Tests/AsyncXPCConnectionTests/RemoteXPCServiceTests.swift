import XCTest
import AsyncXPCConnection

@objc protocol XPCProtocol {
	func noReturnFunction()
}

final class RemoteXPCServiceTests: XCTestCase {
    func testRemoteProtocolInit() throws {
		let conn = NSXPCConnection()
		let _ = RemoteXPCService<XPCProtocol>(connection: conn, remoteInterface: XPCProtocol.self)

		XCTAssertTrue(true)
    }
}
