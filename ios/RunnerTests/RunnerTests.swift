import XCTest
@testable import Runner

@MainActor
final class RunnerTests: XCTestCase {
  func testEncryptedQueueBoundsAndPurge() throws {
    let tracker = PathsLocationTracker()
    defer { tracker.stop() }
    let result = try tracker.runQueueProbe()
    XCTAssertEqual(result, ["capped": true, "expired": true, "purged": true])
  }
}
