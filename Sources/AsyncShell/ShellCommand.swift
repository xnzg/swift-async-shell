import Foundation

public struct Shell: Sendable {
    let name: String

    public init(_ name: String) {
        self.name = name
    }
}

extension Shell: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        name = value
    }

    public static let bash: Shell = "bash"
    public static let zsh: Shell = "zsh"

    public static let `default`: Shell = {
        if nil != FileManager.default.executablePath(for: "zsh") {
            return "zsh"
        }
        return "bash"
    }()
}

public struct ShellCommand: ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    public var shell: Shell = .default
    public private(set) var raw: String
    public private(set) var environment: [String: String] = [:]

    public init(_ value: ShellCommand) {
        self = value
    }

    public init(stringLiteral: String) {
        raw = stringLiteral
    }

    public init(stringInterpolation: StringInterpolation) {
        raw = stringInterpolation.raw
    }

    public subscript(name: String) -> String? {
        get { environment[name] }
        set { environment[name] = newValue }
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var raw: String = ""

        public init(literalCapacity: Int, interpolationCount: Int) {
            raw.reserveCapacity(literalCapacity * 2)
        }

        public mutating func appendLiteral(_ literal: String) {
            raw.append(literal)
        }

        public mutating func appendInterpolation<S: StringProtocol>(raw string: S) {
            raw += string
        }

        public mutating func appendInterpolation(raw: ShellCommand) {
            self.raw += raw.raw
        }

        public mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T) {
            appendInterpolation(value.description)
        }

        public mutating func appendInterpolation<S: StringProtocol>(_ string: S) {
            appendInterpolation(singleQuote: string)
        }

        public mutating func appendInterpolation<S: StringProtocol>(singleQuote string: S) {
            raw.append("'")
            raw += string
            raw.append("'")
        }

        public mutating func appendInterpolation<S: StringProtocol>(doubleQuote string: S) {
            raw.append("\"")
            raw += string
            raw.append("\"")
        }
    }
}

extension ShellCommand: ProcessDescribing {
    public var launchPath: String {
        FileManager.default.executablePath(for: shell.name)!
    }

    public var arguments: [String] {
        ["-c", raw]
    }
}
