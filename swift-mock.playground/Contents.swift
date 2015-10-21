//
//  Mocks.swift
//  delphi-ios
//
//  Created by Sven Meyer on 19/10/15.
//  Copyright © 2015 Meyer & Bruijnes. All rights reserved.
//

// Call pattern

enum CallPattern {
    case None
    case AnyNumber
    case AtLeast(Int)
    case AtMost(Int)
    case Exactly(Int)
}

// for usage in switch

func ~=(pattern: CallPattern, value: Int) -> Bool {
    switch (pattern) {
    case .None: return value == 0
    case .AnyNumber: return true
    case let .AtLeast(n): return value >= n
    case let .AtMost(n): return value <= n
    case let .Exactly(n): return value == n
    }
}

// for mocking a method

struct Mock<Instance, In, Out> {
    let original: (Instance -> In -> Out)!
    let stub: (In -> Out)!
    
    var numberOfCalls = 0
    let expectedCalls: CallPattern!
    
    mutating func call(arg: In) -> Out {
        numberOfCalls++
        return stub(arg)
    }
    
    init(stub: In -> Out, pattern: CallPattern = CallPattern.AnyNumber) {
        self.original = nil
        self.stub = stub
        self.expectedCalls = pattern
    }
    
    init(method: Instance -> In -> Out) {
        self.original = method
        self.stub = nil
        self.expectedCalls = nil
    }
    
    func verify(file: String = __FILE__, line: UInt = __LINE__) -> (Bool, String) {
        switch (numberOfCalls) {
        case expectedCalls:
            return (true, "") // using this in an XCTest you would probably just break here
        default:
            return (false, "\(numberOfCalls) does not match call pattern \(expectedCalls)")
            
            // when using this in an XCTest you would probably do something like this:
            // XCTFail("\(numberOfCalls) does not match call pattern \(expectedCalls)", file:file, line:line)
        }
    }
}

// convenience functions

func mock<Instance, Out>(@autoclosure(escaping) value: () -> Out, pattern: CallPattern = CallPattern.AnyNumber) -> Mock<Instance, Void, Out> {
    return Mock(stub: value, pattern: pattern)
}

func mock<Instance>(pattern: CallPattern = CallPattern.AnyNumber) -> Mock<Instance, Void, Void> {
    return Mock(stub: {}, pattern: pattern)
}

func mock<Instance, In, Out>(pattern: CallPattern = CallPattern.AnyNumber, stub: In -> Out) -> Mock<Instance, In, Out> {
    return Mock(stub: stub, pattern: pattern)
}

// for setting type based on method reference

func mockOf<S, T, U>(original: S -> T -> U) -> Mock<S, T, U> {
    return Mock(method: original)
}

// usage examples

protocol Stuff {
    func a()
    func b(x: Int)
    func c(x: Int, y: Int) -> Int
}

class MockStuff : Stuff {
    func a() {
        // hook up mock object by calling it from the appropriate method
        mockA.call()
    }
    
    func b(x: Int) {
        mockB.call(x)
    }
    
    func c(x: Int, y: Int) -> Int {
        return mockC.call(x, y: y)
    }
    
    // mock storage properties
    var mockA = mockOf(a)
    var mockB = mockOf(b)
    var mockC = mockOf(c)
}

// create mock
let m = MockStuff()

// set expectations
m.mockA = mock(CallPattern.AtLeast(1))
m.mockB = mock(CallPattern.None) { _ in } // ignore first argument, allow any number of calls


// run SUT (which calls mocks)

m.a() // calling, like expected
m.b(4) // calling, even though expectation is none

// verify if expectations were met
m.mockA.verify() // expectation met
m.mockB.verify() // expectation NOT met