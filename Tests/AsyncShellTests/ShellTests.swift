import XCTest
import AsyncShell

final class ShellTests: XCTestCase {
    @available(macOS 12.0, *)
    func testEcho() async throws {
        let output = try await ShellCommand("echo hello world").launchForString()
        XCTAssertEqual(output, "hello world\n")
    }

    @available(macOS 12.0, *)
    func testDoubleEcho() async throws {
        let pipe = Pipe()
        let output: String = try await ShellCommand("echo hello world").launch(standardOutput: pipe) {
            try await ShellCommand("cat").launchForString(standardInput: pipe)
        }
        XCTAssertEqual(output, "hello world\n")
    }

    func testThrowOnNonzeroExit() async throws {
        let reason = try await ShellCommand("false").launch()
        XCTAssertEqual(reason, 1)

        do {
            try await ShellCommand("false").launch { return }
        } catch {
            XCTAssertEqual((error as? ProcessError)?.status, 1)
        }
    }
}
