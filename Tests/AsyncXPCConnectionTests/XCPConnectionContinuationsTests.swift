import XCTest
import AsyncXPCConnection

final class XCPConnectionContinuationTests: XCTestCase {
	func testWithContinuation() async throws {
		let conn = NSXPCConnection()

		conn.remoteObjectInterface = NSXPCInterface(with: XPCProtocol.self)

		let value = try await conn.withContinuation { (service: XPCProtocol, continuation: CheckedContinuation<Int, Error>) in
			// cannot actually make a call to service here because this connection is not real
			continuation.resume(returning: 42)
		}

		XCTAssertEqual(value, 42)
	}
}

