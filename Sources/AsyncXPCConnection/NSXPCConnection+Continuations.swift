import Combine
import Foundation

enum ConnectionContinuationError: Error {
	case serviceTypeMismatch
	case missingBothValueAndError
}

extension NSXPCConnection {
#if compiler(<6.0)
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
#else
	/// Begins remote method invocation that returns a value.
	public func withContinuation<Service, Value>(
		isolation: isolated (any Actor)? = #isolation,
		function: String = #function,
		_ body: (Service, CheckedContinuation<Value, Error>) -> Void
	) async throws -> Value {
		try await withCheckedThrowingContinuation(isolation: isolation, function: function) { continuation in
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
#endif

#if compiler(>=6.0)
	@available(*, deprecated, message: "please use withContinuation(isolation:function:_:)")
#endif
	/// Begins remote method invocation that returns a value.
	public func withContinuation<Service, Value>(
		function: String = #function,
		on actor: isolated some Actor,
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
	
#if compiler(<6.0)
	/// Begins remote method invocation.
	///
	/// Even though the remote call does not return errors, this function still throws because communication can always fail.
	@_unsafeInheritExecutor
	public func withService<Service>(
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
#else
	/// Begins remote method invocation.
	///
	/// Even though the remote call does not return errors, this function still throws because communication can always fail.
	public func withService<Service>(
		isolation: isolated (any Actor)? = #isolation,
		function: String = #function,
		_ body: (Service) throws -> Void
	) async throws {
		try await withContinuation(isolation: isolation, function: function, { (service: Service, continuation: CheckedContinuation<Void, Error>) in
			do {
				try body(service)

				continuation.resume()
			} catch {
				continuation.resume(throwing: error)
			}
		})
	}
#endif

	/// Begins remote method invocation.
	///
	/// Even though the remote call does not return errors, this function still throws because communication can always fail.
#if compiler(>=6.0)
	@available(*, deprecated, message: "please use withService(isolation:function:_:)")
#endif
	public func withService<Service>(
		function: String = #function,
		on actor: isolated some Actor,
		_ body: (Service) throws -> Void
	) async throws {
		try await withContinuation(function: function, on: actor, { (service: Service, continuation: CheckedContinuation<Void, Error>) in
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
#if compiler(<6.0)
	/// Begins remote method invocation that calls out to a value-error pair completion handler.
	///
	/// This function always throws if an error is returned from the completion handler.
	@_unsafeInheritExecutor
	public func withValueErrorCompletion<Service, Value: Sendable>(
		function: String = #function,
		_ body: (Service, @escaping @Sendable (Value?, Error?) -> Void) -> Void
	) async throws -> Value {
		try await withContinuation(function: function) { service, continuation in
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
#else
	/// Begins remote method invocation that calls out to a value-error pair completion handler.
	///
	/// This function always throws if an error is returned from the completion handler.
	/// > Note: The `Value: Sendable` should not be required...
	public func withValueErrorCompletion<Service, Value: Sendable>(
		isolation: isolated (any Actor)? = #isolation,
		function: String = #function,
		_ body: (Service, sending @escaping (Value?, Error?) -> Void) -> Void
	) async throws -> Value {
		try await withContinuation(isolation: isolation, function: function) { service, continuation in
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
#endif

	/// Begins remote method invocation that calls out to a value-error pair completion handler.
	///
	/// This function always throws if an error is returned from the completion handler.
#if compiler(>=6.0)
	@available(*, deprecated, message: "please use withValueErrorCompletion(isolation:function:_:)")
#endif
	public func withValueErrorCompletion<Service, Value: Sendable>(
		function: String = #function,
		on actor: isolated some Actor,
		_ body: (Service, @escaping @Sendable (Value?, Error?) -> Void) -> Void
	) async throws -> Value {
		try await withContinuation(function: function, on: actor) { service, continuation in
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

#if compiler(<6.0)
	/// Begins remote method invocation that calls out to a Result-based completion handler.
	@_unsafeInheritExecutor
	public func withResultCompletion<Service, Value: Sendable>(
		function: String = #function,
		_ body: (Service, @escaping @Sendable (Result<Value, Error>) -> Void) -> Void
	) async throws -> Value {
		try await withContinuation(function: function) { service, continuation in
			body(service) { result in
				continuation.resume(with: result)
			}
		}
	}
#else
	/// Begins remote method invocation that calls out to a Result-based completion handler.
	/// > Note: The `Value: Sendable` should not be required...
	public func withResultCompletion<Service, Value: Sendable>(
		isolation: isolated (any Actor)? = #isolation,
		function: String = #function,
		_ body: (Service, sending @escaping (Result<Value, Error>) -> Void) -> Void
	) async throws -> Value {
		try await withContinuation(isolation: isolation, function: function) { service, continuation in
			body(service) { result in
				continuation.resume(with: result)
			}
		}
	}
#endif

	/// Begins remote method invocation that calls out to a Result-based completion handler.
#if compiler(>=6.0)
	@available(*, deprecated, message: "please use withResultCompletion(isolation:function:_:)")
#endif
	public func withResultCompletion<Service, Value: Sendable>(
		function: String = #function,
		on actor: isolated some Actor,
		_ body: (Service, @escaping @Sendable (Result<Value, Error>) -> Void) -> Void
	) async throws -> Value {
		try await withContinuation(function: function, on: actor) { service, continuation in
			body(service) { result in
				continuation.resume(with: result)
			}
		}
	}

#if compiler(<6.0)
	/// Begins remote method invocation that calls out to a failable completion handler.
	@_unsafeInheritExecutor
	public func withErrorCompletion<Service>(
		function: String = #function,
		_ body: (Service, @escaping @Sendable (Error?) -> Void) -> Void
	) async throws {
		try await withContinuation(function: function) { (service, continuation: CheckedContinuation<Void, Error>) in
			body(service) { error in
				if let error = error {
					continuation.resume(throwing: error)
				} else {
					continuation.resume()
				}
			}
		}
	}
#else
	/// Begins remote method invocation that calls out to a failable completion handler.
	public func withErrorCompletion<Service>(
		isolation: isolated (any Actor)? = #isolation,
		function: String = #function,
		_ body: (Service, sending @escaping (Error?) -> Void) -> Void
	) async throws {
		try await withContinuation(isolation: isolation, function: function) { (service, continuation: CheckedContinuation<Void, Error>) in
			body(service) { error in
				if let error = error {
					continuation.resume(throwing: error)
				} else {
					continuation.resume()
				}
			}
		}
	}
#endif

	/// Begins remote method invocation that calls out to a failable completion handler.
#if compiler(>=6.0)
	@available(*, deprecated, message: "please use withErrorCompletion(isolation:function:_:)")
#endif
	public func withErrorCompletion<Service>(
		function: String = #function,
		on actor: isolated some Actor,
		_ body: (Service, @escaping @Sendable (Error?) -> Void) -> Void
	) async throws {
		try await withContinuation(function: function, on: actor) { (service, continuation: CheckedContinuation<Void, Error>) in
			body(service) { error in
				if let error = error {
					continuation.resume(throwing: error)
				} else {
					continuation.resume()
				}
			}
		}
	}

#if compiler(<6.0)
	@_unsafeInheritExecutor
	public func withDecodingCompletion<Service, Value: Decodable, Decoder: TopLevelDecoder>(
		function: String = #function,
		using decoder: Decoder = JSONDecoder(),
		_ body: (Service, @escaping @Sendable (Data?, Error?) -> Void) -> Void
	) async throws -> Value where Decoder.Input == Data {
		let data: Data = try await withValueErrorCompletion(function: function) { service, handler in
			body(service, handler)
		}

		return try decoder.decode(Value.self, from: data)
	}
#else
	public func withDecodingCompletion<Service, Value: Decodable, Decoder: TopLevelDecoder>(
		isolation: isolated (any Actor)? = #isolation,
		function: String = #function,
		using decoder: Decoder = JSONDecoder(),
		_ body: (Service, sending @escaping (Data?, Error?) -> Void) -> Void
	) async throws -> Value where Decoder.Input == Data {
		let data: Data = try await withValueErrorCompletion(isolation: isolation, function: function) { service, handler in
			body(service, handler)
		}

		return try decoder.decode(Value.self, from: data)
	}
#endif

#if compiler(>=6.0)
	@available(*, deprecated, message: "please use withDecodingCompletion(isolation:function:using:_:)")
#endif
	public func withDecodingCompletion<Service, Value: Decodable, Decoder: TopLevelDecoder>(
		function: String = #function,
		on actor: isolated some Actor,
		using decoder: Decoder = JSONDecoder(),
		_ body: (Service, @escaping @Sendable (Data?, Error?) -> Void) -> Void
	) async throws -> Value where Decoder.Input == Data {
		let data: Data = try await withValueErrorCompletion(function: function, on: actor) { service, handler in
			body(service, handler)
		}

		return try decoder.decode(Value.self, from: data)
	}
}
