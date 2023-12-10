import Foundation

/// A thin wrapper around NSXPCConnection with a defined service type.
///
/// Due to the strange nature of the `Protocol` type, the generic parameter cannot be used to define the NSXPCConection interface. Still a net win, but definitely annoying.
public struct RemoteXPCService<Service> {
	let connection: NSXPCConnection

	/// Create a new `XPCService` instance with an interface.
	public init(connection: NSXPCConnection, remoteInterface: Protocol) {
		self.connection = connection

		precondition(connection.remoteObjectInterface == nil)
		connection.remoteObjectInterface = NSXPCInterface(with: remoteInterface)
	}

	/// Create a new `XPCService` instance without an explicit interface.
	public init(connection: NSXPCConnection) {
		self.connection = connection
	}

	/// Invalidate the underlying connection.
	public func invalidate() {
		connection.invalidate()
	}
}

extension RemoteXPCService {
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

extension RemoteXPCService {
	@_unsafeInheritExecutor
	public func withValueErrorCompletion<Value: Sendable>(
		function: String = #function,
		_ body: (Service, @escaping (Value?, Error?) -> Void) -> Void
	) async throws -> Value {
		try await connection.withValueErrorCompletion(function: function, body)
	}

	@_unsafeInheritExecutor
	public func withResultCompletion<Value: Sendable>(
		function: String = #function,
		_ body: (Service, @escaping (Result<Value, Error>) -> Void) -> Void
	) async throws -> Value {
		try await connection.withResultCompletion(function: function, body)
	}

	@_unsafeInheritExecutor
	public func withErrorCompletion(
		function: String = #function,
		_ body: (Service, @escaping (Error?) -> Void) -> Void
	) async throws {
		try await connection.withErrorCompletion(function: function, body)
	}

	@_unsafeInheritExecutor
	public func withDecodingCompletion<Value: Decodable>(
		function: String = #function,
		_ body: (Service, @escaping (Data?, Error?) -> Void) -> Void
	) async throws -> Value {
		try await connection.withDecodingCompletion(function: function, body)
	}
}
