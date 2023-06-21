[![License][license badge]][license]
[![Platforms][platforms badge]][platforms]
[![Documentation][documentation badge]][documentation]

# AsyncXPCConnection

Swift concurrency support for NSXPCConnection

This package adds structured concurrency extensions to `NSXPCConnection`. It also includes an additional type called `RemoteConnection` that offers more convenient usage via generics.

Both types include a basic continuation-based function, as well as fire-and-forget and three methods specifically made to make handling Objective-C completion handlers convenient and correct.

Given an XPC service like this:

```swift
protocol XPCService {
    func errorMethod(reply: (Error?) -> Void)
    func valueAndErrorMethod(reply: (String?, Error?) -> Void)
    func dataAndErrorMethod(reply: (Data?, Error?) -> Void)
}

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

_ = try await conn.withValueErrorCompletion { (service: XPCService, handler) in
    service.valueAndErrorMethod(reply: handler)
}
```

You can also make use of the `RemoteConnection` type, which will remove the need for explict typing.

```swift
let conn = NSXPCConnection()
let remote = RemoteConnection<XPCService>(connection: conn, remoteInterface: XPCService.self)

// access to the underlying continuation
try await remote.withContinuation { service, continuation in
    service.errorMethod() {
        if let error = $0 {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }
}

try await remote.withService { service in
    service.method()
}

try await remote.withErrorCompletion {service, handler in
	service.errorMethod(reply: handler)
}

_ = try await remote.withValueErrorCompletion { service, handler in
    service.valueAndErrorMethod(reply: handler)
}
```

## Contributing and Collaboration

I prefer collaboration, and would love to find ways to work together if you have a similar project.

I prefer indentation with tabs for improved accessibility. But, I'd rather you use the system you want and make a PR than hesitate because of whitespace.

## Suggestions and Feedback

I'd love to hear from you! Get in touch via an issue or pull request.

By participating in this project you agree to abide by the [Contributor Code of Conduct](CODE_OF_CONDUCT.md).

[license]: https://opensource.org/licenses/BSD-3-Clause
[license badge]: https://img.shields.io/github/license/ChimeHQ/AsyncXPCConnection
[platforms]: https://swiftpackageindex.com/ChimeHQ/AsyncXPCConnection
[platforms badge]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChimeHQ%2FAsyncXPCConnection%2Fbadge%3Ftype%3Dplatforms
[documentation]: https://swiftpackageindex.com/ChimeHQ/AsyncXPCConnection/main/documentation
[documentation badge]: https://img.shields.io/badge/Documentation-DocC-blue
