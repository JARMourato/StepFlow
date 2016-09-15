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

enum MockErrors: Error {
  case errorOnFlow
}

class FlowTests: XCTestCase {

  func testInitWithArrayOfSteps() {
    let expectation = self.expectation(description: name ?? "Test")

    let stepOne = Step { stepFlow, previousResult in
      XCTAssertNil(previousResult)
      stepFlow.finish("empty step")
    }

    let stepTwo = Step { stepFlow, previousResult in
      XCTAssert("empty step" == previousResult as? String)
      stepFlow.finish("empty step")
    }

    Flow(steps: [stepOne, stepTwo]).onFinish { (state) in
      if case .Finished(_) = state {} else { XCTFail() }
      expectation.fulfill()
    }.start()

    waitForExpectations(timeout: 0.5, handler: nil)
  }

  func testInitWithVariadicArrayOfSteps() {
    let expectation = self.expectation(description: name ?? "Test")

    let stepOne = Step { stepFlow, previousResult in
      XCTAssertNil(previousResult)
      stepFlow.finish("empty step")
    }

    let stepTwo = Step { stepFlow, previousResult in
      XCTAssert("empty step" == previousResult as? String)
      stepFlow.finish("empty step")
    }

    Flow(steps: stepOne, stepTwo).onFinish { (state) in
      if case .Finished(_) = state {} else { XCTFail() }
      expectation.fulfill()
      }.start()

    waitForExpectations(timeout: 0.5, handler: nil)
  }

  func testCancelFlowFallbackToFinishBlock() {
    let expectation = self.expectation(description: name ?? "Test")

    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertFalse(NSThread.currentThread().isMainThread, "Should not be executing on main thread")
      XCTAssertNil(previousResult)
      sleep(2)
      stepFlow.finish("empty step")
    }

    let stepTwo = Step { stepFlow, previousResult in
      XCTAssert("empty step" == previousResult as? String)
      stepFlow.finish("empty step")
    }

    let flow = Flow(steps: stepOne, stepTwo).onFinish { (state) in
      XCTAssertTrue(NSThread.currentThread().isMainThread, "Should be executing on main thread")
      if case .Canceled = state {} else { XCTFail() }
      expectation.fulfill()
    }
    flow.start()
    sleep(1)
    flow.cancel()

    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testErrorOnFlowFallbackToFinishBlock() {
    let expectation = self.expectation(description: name ?? "Test")

    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertFalse(NSThread.currentThread().isMainThread, "Should not be executing on main thread")
      XCTAssertNil(previousResult)
      sleep(2)
      stepFlow.finish("empty step")
    }

    let stepTwo = Step { stepFlow, previousResult in
      XCTAssert("empty step" == previousResult as? String)
      stepFlow.finish(MockErrors.ErrorOnFlow)
    }

    Flow(steps: stepOne, stepTwo).onFinish { (state) in
      XCTAssertTrue(NSThread.currentThread().isMainThread, "Should be executing on main thread")
      if case .Failed = state {} else { XCTFail() }
      expectation.fulfill()
    }.start()

    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testCancelFlowGoesToCancelBlock() {
    let expectation = self.expectation(description: name ?? "Test")

    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertFalse(NSThread.currentThread().isMainThread, "Should not be executing on main thread")
      XCTAssertNil(previousResult)
      sleep(2)
      stepFlow.finish("empty step")
    }

    let stepTwo = Step { stepFlow, previousResult in
      XCTAssert("empty step" == previousResult as? String)
      stepFlow.finish("empty step")
    }

    let flow = Flow(steps: stepOne, stepTwo).onFinish { (state) in
      XCTFail()
    }.onCancel {
      XCTAssertTrue(NSThread.currentThread().isMainThread, "Should be executing on main thread")
      expectation.fulfill()
    }
    flow.start()
    sleep(1)
    flow.cancel()

    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testErrorOnFlowGoesToErrorBlock() {
    let expectation = self.expectation(description: name ?? "Test")

    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertFalse(NSThread.currentThread().isMainThread, "Should not be executing on main thread")
      XCTAssertNil(previousResult)
      sleep(2)
      stepFlow.finish("empty step")
    }

    let stepTwo = Step { stepFlow, previousResult in
      XCTAssert("empty step" == previousResult as? String)
      stepFlow.finish(MockErrors.ErrorOnFlow)
    }

    Flow(steps: stepOne, stepTwo).onFinish { (state) in
      XCTFail()
    }.onError({ (error) in
      XCTAssertTrue(NSThread.currentThread().isMainThread, "Should be executing on main thread")
      XCTAssert(error as? MockErrors == MockErrors.ErrorOnFlow)
      expectation.fulfill()
    }).start()

    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testRunFlowWithoutSteps() {
    let flow = Flow(steps: [])
    flow.start()
    if case .Queued = flow.state {} else { XCTFail() }

    let flowVariadic = Flow()
    flowVariadic.start()
    if case .Queued = flowVariadic.state {} else { XCTFail() }
  }

  func testTryStartAfterFlowBeginning() {
    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertNil(previousResult)
      sleep(2)
      stepFlow.finish("empty step")
    }
    let flow = Flow(steps: [stepOne])
    flow.start()
    if case .Running = flow.state {} else { XCTFail() }
    flow.start()
    if case .Running = flow.state {} else { XCTFail() }
  }

  func testTryModifyingCancelBlockAfterStartingFlow() {
    let expectation = self.expectation(description: name ?? "Test")
    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertNil(previousResult)
      sleep(2)
      stepFlow.finish("empty step")
    }
    let flow = Flow(steps: [stepOne]).onCancel {
      expectation.fulfill()
    }
    flow.start()

    flow.onCancel {
      XCTFail()
    }
    sleep(1)
    flow.cancel()
    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testTryModifyingErrorBlockAfterStartingFlow() {
    let expectation = self.expectation(description: name ?? "Test")
    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertNil(previousResult)
      sleep(2)
      stepFlow.finish(MockErrors.ErrorOnFlow)
    }
    let flow = Flow(steps: [stepOne]).onError { _ in
      expectation.fulfill()
    }
    flow.start()

    flow.onError { _ in
      XCTFail()
    }
    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testTryModifyingFinishBlockAfterStartingFlow() {
    let expectation = self.expectation(description: name ?? "Test")
    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertNil(previousResult)
      sleep(2)
      stepFlow.finish(MockErrors.ErrorOnFlow)
    }
    let flow = Flow(steps: [stepOne]).onFinish { _ in
      expectation.fulfill()
    }
    flow.start()

    flow.onFinish { _ in
      XCTFail()
    }
    waitForExpectations(timeout: 5.0, handler: nil)
  }

  func testRunFlowWithNoFinishBlock() {
    let expectationOne = expectation(description: name ?? "Test")
    let stepOne = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertNil(previousResult)
      stepFlow.finish("Finished")
      expectationOne.fulfill()
    }
    Flow(steps: [stepOne]).start()
    waitForExpectations(timeout: 5.0, handler: nil)

    let expectationTwo = expectation(description: name ?? "Test")
    let stepTwo = Step(onBackgroundThread: true) { stepFlow, previousResult in
      XCTAssertNil(previousResult)
      stepFlow.finish("Finished")
      expectationTwo.fulfill()
    }
    Flow(steps: stepTwo).start()
    waitForExpectations(timeout: 5.0, handler: nil)
  }

}
