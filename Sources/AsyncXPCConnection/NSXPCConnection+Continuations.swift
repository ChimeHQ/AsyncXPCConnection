import Foundation

enum ConnectionContinuationError: Error {
	case serviceTypeMismatch
	case missingBothValueAndError
}

extension NSXPCConnection {
	/// Begins remote method invocation that returns a value.
	@_unsafeInheritExecutor
	public func withContinuation<Service, Value>(
		function: String = #function,
		_ body: (Service, CheckedContinuation<Value, Error>) -> Void
	) async throws -> Value {
		return try await withCheckedThrowingContinuation(function: function) { continuation in
			let proxy = self.remoteObjectProxyWithErrorHandler { error in
				continuation.resume(throwing: error)
			}

			guard let service = proxy as? Service else {
				continuation.resume(throwing: ConnectionContinuationError.serviceTypeMismatch)
				return
			}

			body(service, continuation)
		}
	}

	/// Begins remote method invocation.
	///
	/// Even though the remote call does not return errors, this function still throws because communication can always fail.
	@_unsafeInheritExecutor
	func withService<Service>(
		function: String = #function,
		_ body: (Service) throws -> Void
	) async throws {
		try await withContinuation(function: function, { (service: Service, continuation: CheckedContinuation<Void, Error>) in
			do {
				try body(service)

				continuation.resume()
			} catch {
				continuation.resume(throwing: error)
			}
		})
	}
}

extension NSXPCConnection {
	/// Begins remote method invocation that calls out to a value-error pair completion handler.
	///
	/// This function always throws if an error is returned from the completion handler.
	@_unsafeInheritExecutor
	public func withValueErrorCompletion<Service, Value>(
		function: String = #function,
		_ body: (Service, (Value?, Error?) -> Void) -> Void
	) async throws -> Value {
		try await withContinuation { service, continuation in
			body(service) { value, error in
				switch (value, error) {
				case let (value?, nil):
					continuation.resume(returning: value)
				case let (nil, error?):
					continuation.resume(throwing: error)
				case let (_, error?):
					continuation.resume(throwing: error)
				case (nil, nil):
					continuation.resume(throwing: ConnectionContinuationError.missingBothValueAndError)
				}
			}
		}
	}

	/// Begins remote method invocation that calls out to a Result-based completion handler.
	@_unsafeInheritExecutor
	public func withResultCompletion<Service, Value>(
		function: String = #function,
		_ body: (Service, (Result<Value, Error>) -> Void) -> Void
	) async throws -> Value {
		try await withContinuation { service, continuation in
			body(service) { result in
				continuation.resume(with: result)
			}
		}
	}

	/// Begins remote method invocation that calls out to a failable completion handler.
	@_unsafeInheritExecutor
	public func withErrorCompletion<Service>(
		function: String = #function,
		_ body: (Service, (Error?) -> Void) -> Void
	) async throws {
		try await withContinuation { (service, continuation: CheckedContinuation<Void, Error>) in
			body(service) { error in
				if let error = error {
					continuation.resume(throwing: error)
				} else {
					continuation.resume()
				}
			}
		}
	}
}

@objc protocol XPCService {
	func method()
	func errorMethod(reply: (Error?) -> Void)
	func valueAndErrorMethod(reply: (String?, Error?) -> Void)
}

func testFunc() async throws {
	let conn = NSXPCConnection()
	conn.remoteObjectInterface = NSXPCInterface(with: XPCService.self)

	// access to the underlying continuation
	try await conn.withContinuation { (service: XPCService, continuation: CheckedContinuation<Void, Error>) in
		service.errorMethod() {
			if let error = $0 {
				continuation.resume(throwing: error)
			} else {
				continuation.resume()
			}
		}
	}

	try await conn.withService { (service: XPCService) in
		service.method()
	}

	try await conn.withErrorCompletion { (service: XPCService, handler) in
		service.errorMethod(reply: handler)
	}

	_ = try await conn.withValueErrorCompletion { (service: XPCService, handler) in
		service.valueAndErrorMethod(reply: handler)
	}
}
