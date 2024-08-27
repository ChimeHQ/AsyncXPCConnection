<div align="center">

[![Build Status][build status badge]][build status]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]
[![Matrix][matrix badge]][matrix]

</div>

# AsyncXPCConnection

Swift concurrency support for NSXPCConnection

Features:
- structured concurrency extensions for `NSXPCConnection`
- convenience callbacks for better interfacing with Objective-C-based XPC protocols
- `RemoteXPCService` for easier type-safety
- `QueuedRemoteXPCService` for message ordering control

You might be tempted to just make your XPC interface functions async. While the compiler does support this, it is very unsafe. This approach does not handle connection failures and will results in hangs.

## Usage

Given an XPC service like this:

```swift
@objc
protocol XPCService {
    func method()
    func errorMethod(reply: (Error?) -> Void)
    func valueAndErrorMethod(reply: (String?, Error?) -> Void)
    func dataAndErrorMethod(reply: (Data?, Error?) -> Void)
}
```

You can use `NSXCPConnection` directly:

```swift
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

let value = try await conn.withValueErrorCompletion { (service: XPCService, handler) in
    service.valueAndErrorMethod(reply: handler)
}

let decodedValue = try await conn.withDecodingCompletion { (service: XPCService, handler) in
    service.dataAndErrorMethod(reply: handler)
}
```

You can also make use of the `RemoteXPCService` type, which will remove the need for explicit typing of the service.

```swift
let conn = NSXPCConnection()
let remote = RemoteXPCService<XPCService>(connection: conn, remoteInterface: XPCService.self)

let decodedValue = try await remote.withDecodingCompletion { service, handler in
    service.dataAndErrorMethod(reply: handler)
}
```

## Ordering

The `QueuedRemoteXPCService` type is very similar to `RemoteXPCService`, but offers a queuing interface to control the ordering of message delivery. This is done via the `AsyncQueuing` protocol, for flexible, dependency-free support. If you need a compatible queue implementation, check out [Queue][queue]. And, if you know of another, let me know so I can link to it.

```swift
import AsyncXPCConnection
import Queue

extension AsyncQueue: AsyncQueuing {}

let queue = AsyncQueue()
let connection = NSXPCConnection()
let queuedService = QueuedRemoteXPCService<XPCService, AsyncQueue>(queue: queue, provider: { connection })

queuedService.addOperation { service in
    service.method()
}

let value = try await queuedService.addDecodingOperation { service, handler in
    service.dataAndErrorMethod(reply: handler)
}
```

## Alternatives

- [SecureXPC](https://github.com/trilemma-dev/SecureXPC)
- [SwiftyXPC](https://github.com/CharlesJS/SwiftyXPC)

## Contributing and Collaboration

I would love to hear from you! Issues or pull requests work great. Both a [Matrix space][matrix] and [Discord][discord] are available for live help, but I have a strong bias towards answering in the form of documentation. You can also find me on [mastodon](https://mastodon.social/@mattiem).

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[build status]: https://github.com/ChimeHQ/AsyncXPCConnection/actions
[build status badge]: https://github.com/ChimeHQ/AsyncXPCConnection/workflows/CI/badge.svg
[platforms]: https://swiftpackageindex.com/ChimeHQ/AsyncXPCConnection
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FAsyncXPCConnection%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/ChimeHQ/AsyncXPCConnection/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
[matrix]: https://matrix.to/#/%23chimehq%3Amatrix.org
[matrix badge]: https://img.shields.io/matrix/chimehq%3Amatrix.org?label=Matrix
[discord]: https://discord.gg/esFpX6sErJ
[queue]: https://github.com/mattmassicotte/Queue
