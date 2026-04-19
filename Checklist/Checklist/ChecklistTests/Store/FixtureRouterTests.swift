/// FixtureRouterTests.swift
/// Purpose: Unit tests for FixtureRouter URL parsing.

import XCTest
@testable import Checklist

final class FixtureRouterTests: XCTestCase {
    func test_valid_seedMulti_url_parses() {
        let url = URL(string: "checklist://seed/seededMulti")!
        XCTAssertEqual(FixtureRouter.fixture(from: url), .seededMulti)
    }

    func test_valid_empty_url_parses() {
        let url = URL(string: "checklist://seed/empty")!
        XCTAssertEqual(FixtureRouter.fixture(from: url), .empty)
    }

    func test_wrong_scheme_returns_nil() {
        let url = URL(string: "http://seed/empty")!
        XCTAssertNil(FixtureRouter.fixture(from: url))
    }

    func test_unknown_fixture_name_returns_nil() {
        let url = URL(string: "checklist://seed/notARealFixture")!
        XCTAssertNil(FixtureRouter.fixture(from: url))
    }

    func test_wrong_host_returns_nil() {
        let url = URL(string: "checklist://somethingelse/empty")!
        XCTAssertNil(FixtureRouter.fixture(from: url))
    }
}
