import Combine
import Foundation

public protocol AsyncQueuing {
	@discardableResult
	func addOperation<Success>(
		priority: TaskPriority?,
		barrier: Bool,
		@_inheritActorContext operation: @escaping @Sendable () async throws -> Success
	) -> Task<Success, Error> where Success : Sendable
}

@MainActor
public struct QueuedRemoteXPCService<Service, Queue: AsyncQueuing> {
	public typealias ConnectionProvider = @MainActor () async throws -> NSXPCConnection

	let queue: Queue
	private let provider: ConnectionProvider

	public init(queue: Queue, provider: @escaping ConnectionProvider) {
		self.queue = queue
		self.provider = provider
	}

	public init(queue: Queue, connection: NSXPCConnection) {
		self.queue = queue
		self.provider = { connection }
	}
}

extension QueuedRemoteXPCService {
	public func addOperation(
		barrier: Bool = false,
		@_inheritActorContext operation: @escaping (Service) throws -> Void) {
		queue.addOperation(priority: nil, barrier: barrier) {
			let conn = try await provider()
			try await conn.withService { service in
				try operation(service)
			}
		}
	}
}

extension QueuedRemoteXPCService {
	public typealias ResultOperationHandler<Value> = (Result<Value, Error>) -> Void
	public typealias ErrorOperationHandler = (Error?) -> Void
	public typealias ValueErrorOperationHandler<Value> = (Value?, Error?) -> Void

	public func addResultOperation<Value: Sendable>(
		barrier: Bool = false,
		operation: @escaping (Service, sending @escaping ResultOperationHandler<Value>) -> Void
	) async throws -> Value {
		let task: Task<Value, Error> = queue.addOperation(priority: nil, barrier: barrier) {
			let conn = try await provider()

			return try await conn.withResultCompletion { service, handler in
				operation(service, handler)
			}
		}

		return try await task.value
	}

	public func addErrorOperation(
		barrier: Bool = false,
		operation: @escaping (Service, sending @escaping ErrorOperationHandler) -> Void
	) async throws {
		let task: Task<Void, Error> = queue.addOperation(priority: nil, barrier: barrier) {
			let conn = try await provider()

			try await conn.withErrorCompletion { service, handler in
				operation(service, handler)
			}
		}

		return try await task.value
	}

	public func addDiscardingErrorOperation(
		barrier: Bool = false,
		operation: @escaping (Service, sending @escaping ErrorOperationHandler) -> Void
	) {
		queue.addOperation(priority: nil, barrier: barrier) {
			let conn = try await provider()

			try await conn.withErrorCompletion { service, handler in
				operation(service, handler)
			}
		}
	}

	public func addValueErrorOperation<Value: Sendable>(
		barrier: Bool = false,
		operation: @escaping (Service, sending @escaping ValueErrorOperationHandler<Value>) -> Void
	) async throws -> Value {
		let task: Task<Value, Error> = queue.addOperation(priority: nil, barrier: barrier) {
			let conn = try await provider()

			return try await conn.withValueErrorCompletion { service, handler in
				operation(service, handler)
			}
		}

		return try await task.value
	}

	public func addDecodingOperation<Value: Sendable & Decodable, Decoder: TopLevelDecoder>(
		barrier: Bool = false,
		using decoder: Decoder = JSONDecoder(),
		operation: @escaping (Service, sending @escaping ValueErrorOperationHandler<Data>) -> Void
	) async throws -> Value where Decoder.Input == Data {
		let task: Task<Value, Error> = queue.addOperation(priority: nil, barrier: barrier) {
			let conn = try await provider()

			return try await conn.withDecodingCompletion(using: decoder) { service, handler in
				operation(service, handler)
			}
		}

		return try await task.value
	}
}
