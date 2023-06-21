import Foundation

/// A thin wrapper around NSXPCConnection with a defined service type.
///
/// Due to the strange nature of the `Protocol` type, the generic parameter cannot be used to define the NSXPCConection interface. Still a net win, but definitely annoying.
public struct RemoteConnection<Service> {
	let connection: NSXPCConnection

	/// Create a new `RemoteConnection` instance.
	public init(connection: NSXPCConnection, remoteInterface: Protocol) {
		self.connection = connection

		precondition(connection.remoteObjectInterface == nil)
		connection.remoteObjectInterface = NSXPCInterface(with: remoteInterface)
	}
}

extension RemoteConnection {
	@_unsafeInheritExecutor
	public func withContinuation<T>(
		function: String = #function,
		_ body: (Service, CheckedContinuation<T, Error>) -> Void
	) async throws -> T {
		try await connection.withContinuation(function: function, body)
	}

	@_unsafeInheritExecutor
	public func withService(
		function: String = #function,
		_ body: (Service) throws -> Void
	) async throws {
		try await connection.withService(function: function, body)
	}
}

extension RemoteConnection {
	@_unsafeInheritExecutor
	public func withValueErrorCompletion<Value>(
		function: String = #function,
		_ body: (Service, (Value?, Error?) -> Void) -> Void
	) async throws -> Value {
		try await connection.withValueErrorCompletion(function: function, body)
	}

	@_unsafeInheritExecutor
	public func withResultCompletion<Value>(
		function: String = #function,
		_ body: (Service, (Result<Value, Error>) -> Void) -> Void
	) async throws -> Value {
		try await connection.withResultCompletion(function: function, body)
	}

	@_unsafeInheritExecutor
	public func withErrorCompletion(
		function: String = #function,
		_ body: (Service, (Error?) -> Void) -> Void
	) async throws {
		try await connection.withErrorCompletion(function: function, body)
	}
}
