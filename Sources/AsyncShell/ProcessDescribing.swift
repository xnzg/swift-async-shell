import Foundation
import AsyncAlgorithms

public protocol ProcessDescribing {
    var launchPath: String { get }
    var arguments: [String] { get }
    var environment: [String: String]? { get }
}

extension ProcessDescribing {
    public var environment: [String: String]? {
        nil
    }

    func update(_ process: Process) {
        process.launchPath = launchPath
        process.arguments = arguments
        if let environment = environment {
            process.environment = environment
        }
    }
}

public struct ProcessError: Error {
    public var status: Int
}

public extension ProcessDescribing {
    func launch(
        standardInput: (any ProcessInput)? = nil,
        standardOutput: (any ProcessOutput)? = nil,
        standardError: (any ProcessOutput)? = nil
    ) async throws -> Int {
        let process = Process()

        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.environment = environment

        if let standardInput = standardInput {
            process.standardInput = try standardInput.resolveProcessInput()
        }
        if let standardOutput = standardOutput {
            process.standardOutput = try standardOutput.resolveProcessOutput()
        }
        if let standardError = standardError {
            process.standardError = try standardError.resolveProcessOutput()
        }

        let task = Task<Int, Never> {
            await withCheckedContinuation { cont in
                process.terminationHandler = {
                    cont.resume(returning: Int($0.terminationStatus))
                }
            }
        }
        try process.run()
        return await task.value
    }

    func launchAsEmptyStream<T>(
        of type: T.Type = T.self,
        standardInput: (any ProcessInput)? = nil,
        standardOutput: (any ProcessOutput)? = nil,
        standardError: (any ProcessOutput)? = nil
    ) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream {
            let status = try await launch(
                standardInput: standardInput,
                standardOutput: standardOutput,
                standardError: standardError)
            guard status == 0 else {
                throw ProcessError(status: status)
            }
            return nil
        }
    }
}

@available(macOS 12.0, *)
extension ProcessDescribing {
    func launchForBytes()
    -> AsyncMerge2Sequence<FileHandle.AsyncBytes, AsyncThrowingStream<UInt8, Error>>
    {
        let pipe = Pipe()
        return merge(
            pipe.fileHandleForReading.bytes,
            launchAsEmptyStream(standardOutput: pipe))
    }

    func launchForLines()
    -> AsyncMerge2Sequence<AsyncLineSequence<FileHandle.AsyncBytes>, AsyncThrowingStream<String, Error>>
    {
        let pipe = Pipe()
        return merge(
            pipe.fileHandleForReading.bytes.lines,
            launchAsEmptyStream(standardOutput: pipe))
    }
}
