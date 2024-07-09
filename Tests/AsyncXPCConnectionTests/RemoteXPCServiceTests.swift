import XCTest
import AsyncXPCConnection

@objc protocol XPCProtocol {
	func noReturnFunction()
}

final class RemoteXPCServiceTests: XCTestCase {
    func testWithContinuation() async throws {
		let conn = NSXPCConnection()
		let service = RemoteXPCService<XPCProtocol>(connection: conn, remoteInterface: XPCProtocol.self)

		let value = try await service.withContinuation { (_, continuation: CheckedContinuation<Int, Error>) in
			continuation.resume(returning: 42)
		}

		XCTAssertEqual(value, 42)
    }
}
