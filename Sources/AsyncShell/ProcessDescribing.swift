import Foundation

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

    func launch<Result>(
        standardInput: (any ProcessInput)? = nil,
        standardOutput: (any ProcessOutput)? = nil,
        standardError: (any ProcessOutput)? = nil,
        andPerform sidework: () async throws -> Result
    ) async throws -> Result {
        async let status = launch(
            standardInput: standardInput,
            standardOutput: standardOutput,
            standardError: standardError)
        async let result = sidework()

        guard try await status == 0 else {
            throw ProcessError(status: try await status)
        }
        return try await result
    }

    @available(macOS 12.0, *)
    func launchToProcessOutput<Result>(
        standardInput: (any ProcessInput)? = nil,
        standardError: (any ProcessOutput)? = nil,
        process: (FileHandle.AsyncBytes) async throws -> Result
    ) async throws -> Result {
        let pipe = Pipe()
        return try await launch(
            standardInput: standardInput,
            standardOutput: pipe,
            standardError: standardError
        ) {
            try await process(pipe.fileHandleForReading.bytes)
        }
    }

    @available(macOS 12.0, *)
    func launchForString(
        encoding: String.Encoding = .utf8,
        standardInput: (any ProcessInput)? = nil,
        standardError: (any ProcessOutput)? = nil
    ) async throws -> String {
        try await launchToProcessOutput(
            standardInput: standardInput,
            standardError: standardError
        ) { bytes in
            var data = Data()
            for try await byte in bytes {
                data.append(byte)
            }
            return String(data: data, encoding: encoding)!
        }
    }
}
