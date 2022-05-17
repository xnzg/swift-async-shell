import XCTest
import AsyncShell

final class MapReduceTests: XCTestCase {
    func testLimitCount() async throws {
        actor Counter {
            private(set) var current: Int = 0
            private(set) var max: Int = 0
            private(set) var min: Int = 0

            func incr() {
                current += 1
                max = Swift.max(max, current)
            }

            func decr() {
                current -= 1
                min = Swift.min(min, current)
            }
        }

        let counter1 = Counter()
        await (0..<1000).parallelForEach(concurrentCount: 4) { _ in
            await counter1.incr()
            try! await Task.sleep(nanoseconds: 1000_000)
            await counter1.decr()
        }
        let current1 = await counter1.current
        XCTAssertEqual(current1, 0)
        let max1 = await counter1.max
        XCTAssertEqual(max1, 4)
        let min1 = await counter1.min
        XCTAssertEqual(min1, 0)

        let counter2 = Counter()
        try await (0..<100).throwingParallelForEach(concurrentCount: 1) { _ in
            await counter2.incr()
            try await Task.sleep(nanoseconds: 1000_000)
            await counter2.decr()
        }
        let current2 = await counter2.current
        XCTAssertEqual(current2, 0)
        let max2 = await counter2.max
        XCTAssertEqual(max2, 1)
        let min2 = await counter2.min
        XCTAssertEqual(min2, 0)
    }
}
