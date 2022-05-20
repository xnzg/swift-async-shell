import Foundation

extension Sequence where Element: Sendable {
    public func mapReduce<Intermediate, Result>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        _ initialResult: Result,
        map: @escaping @Sendable (Element) async -> Intermediate,
        reduce: (inout Result, Intermediate) -> Void
    ) async -> Result {
        precondition(concurrentCount >= 1)
        return await withTaskGroup(of: Intermediate.self) { group in
            var i = makeIterator()
            var count = 0
            var sum = initialResult

            while count < concurrentCount, let element = i.next() {
                count += 1
                group.addTask { await map(element) }
            }

            for await next in group {
                reduce(&sum, next)
                guard let element = i.next() else { continue }
                group.addTask { await map(element) }
            }

            return sum
        }
    }

    public func throwingMapReduce<Intermediate, Result>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        _ initialResult: Result,
        map: @escaping @Sendable (Element) async throws -> Intermediate,
        reduce: (inout Result, Intermediate) throws -> Void
    ) async throws -> Result {
        precondition(concurrentCount >= 1)
        return try await withThrowingTaskGroup(of: Intermediate.self) { group in
            var i = makeIterator()
            var count = 0
            var sum = initialResult

            while count < concurrentCount, let element = i.next() {
                count += 1
                group.addTask { try await map(element) }
            }

            for try await next in group {
                try reduce(&sum, next)
                guard let element = i.next() else { continue }
                group.addTask { try await map(element) }
            }

            return sum
        }
    }
}

extension Sequence {
    public func parallelForEach(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        body: @escaping @Sendable (Element) async -> Void
    ) async
    {
        await mapReduce(concurrentCount: concurrentCount, (), map: body) { _, _ in }
    }

    public func throwingParallelForEach(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        body: @escaping @Sendable (Element) async throws -> Void
    ) async throws
    {
        try await throwingMapReduce(concurrentCount: concurrentCount, (), map: body) { _, _ in }
    }

    public func parallelMap<Result>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        body: @escaping @Sendable (Element) async -> Result
    ) async -> [Result]
    {
        await mapReduce(concurrentCount: concurrentCount, [], map: body) {
            $0.append($1)
        }
    }

    public func throwingParallelMap<Result>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        body: @escaping @Sendable (Element) async throws -> Result
    ) async throws -> [Result]
    {
        try await throwingMapReduce(concurrentCount: concurrentCount, [], map: body) {
            $0.append($1)
        }
    }

    public func parallelCompactMap<Result>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        body: @escaping @Sendable (Element) async -> Result?
    ) async -> [Result]
    {
        await mapReduce(concurrentCount: concurrentCount, [], map: body) {
            if let x = $1 {
                $0.append(x)
            }
        }
    }

    public func throwingParallelCompactMap<Result>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        body: @escaping @Sendable (Element) async throws -> Result?
    ) async throws -> [Result]
    {
        try await throwingMapReduce(concurrentCount: concurrentCount, [], map: body) {
            if let x = $1 {
                $0.append(x)
            }
        }
    }

    public func parallelMapToDictionary<Key: Hashable, Value>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        allowsDuplicatedKey: Bool = false,
        body: @escaping @Sendable (Element) async -> (Key, Value)
    ) async -> [Key: Value]
    {
        await mapReduce(concurrentCount: concurrentCount, [:], map: body) {
            assert(allowsDuplicatedKey || $0[$1.0] == nil)
            $0[$1.0] = $1.1
        }
    }

    public func throwingParallelMap<Key: Hashable, Value>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        allowsDuplicatedKey: Bool = false,
        body: @escaping @Sendable (Element) async throws -> (Key, Value)
    ) async throws -> [Key: Value]
    {
        try await throwingMapReduce(concurrentCount: concurrentCount, [:], map: body) {
            assert(allowsDuplicatedKey || $0[$1.0] == nil)
            $0[$1.0] = $1.1
        }
    }

    public func parallelCompactMapToDictionary<Key: Hashable, Value>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        allowsDuplicatedKey: Bool = false,
        body: @escaping @Sendable (Element) async -> (Key, Value)?
    ) async -> [Key: Value]
    {
        await mapReduce(concurrentCount: concurrentCount, [:], map: body) {
            guard let (key, value) = $1 else { return }
            assert(allowsDuplicatedKey || $0[key] == nil)
            $0[key] = value
        }
    }

    public func throwingParallelCompactMapToDictionary<Key: Hashable, Value>(
        concurrentCount: Int = ProcessInfo.processInfo.activeProcessorCount,
        allowsDuplicatedKey: Bool = false,
        body: @escaping @Sendable (Element) async throws -> (Key, Value)?
    ) async throws -> [Key: Value]
    {
        try await throwingMapReduce(concurrentCount: concurrentCount, [:], map: body) {
            guard let (key, value) = $1 else { return }
            assert(allowsDuplicatedKey || $0[key] == nil)
            $0[key] = value
        }
    }
}
