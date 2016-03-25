/*
 Copyright (c) 2016 João Mourato <joao.armourato@gmail.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

import XCTest
import StepFlow

struct MockFlow : StepFlow {
    
    func finish(error: ErrorType) {
        
    }
    
    func finish<T>(result: T) {
        
    }
    
}


class StepTests: XCTestCase {
    
    func testStepOnCallingThread() {
        let expectation = expectationWithDescription(name ?? "Test")
        let step = Step { (stepFlow, result) -> (Void) in
            XCTAssertNil(result)
            expectation.fulfill()
        }
        step.runStep(stepFlowImplementor: MockFlow(), previousResult: nil)
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }
    
    func testStepOnBackgroundThread() {
        let expectation = expectationWithDescription(name ?? "Test")
        let step = Step(onBackgroundThread: true) { (stepFlow, result) -> (Void) in
            XCTAssertNil(result)
            expectation.fulfill()
        }
        step.runStep(stepFlowImplementor: MockFlow(), previousResult: nil)
        waitForExpectationsWithTimeout(0.5, handler: nil)
    }
    
}
