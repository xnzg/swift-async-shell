import Foundation

public protocol ProcessInput {
    func resolveProcessInput() throws -> Any
}
public protocol ProcessOutput {
    func resolveProcessOutput() throws -> Any
}

extension FileHandle: ProcessInput, ProcessOutput {
    public func resolveProcessInput() -> Any {
        self
    }

    public func resolveProcessOutput() -> Any {
        self
    }
}

extension Pipe: ProcessInput, ProcessOutput {
    public func resolveProcessInput() -> Any {
        self
    }

    public func resolveProcessOutput() -> Any {
        self
    }
}

extension URL: ProcessInput, ProcessOutput {
    public func resolveProcessInput() throws -> Any {
        try FileHandle(forReadingFrom: self)
    }

    public func resolveProcessOutput() throws -> Any {
        try FileHandle(forWritingTo: self)
    }
}
