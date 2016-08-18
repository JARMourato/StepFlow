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

import Foundation

public final class Flow {

  private var steps: [Step]
  public typealias FinishBlock = (FlowState<Any>) -> ()
  public typealias ErrorBlock = (ErrorType) -> ()
  public typealias CancelBlock = () -> ()
  private var _onFinish: FinishBlock = { _ in }
  private var _onError: ErrorBlock?
  private var _onCancel: CancelBlock?
  private var _state: FlowState<Any> = .Queued
  private let syncQueue = dispatch_queue_create("com.flow.syncQueue", DISPATCH_QUEUE_CONCURRENT)

  public var state: FlowState<Any> {
    var val: FlowState<Any>?
    dispatch_sync(syncQueue) {
      val = self._state
    }
    return val!
  }

  public init(steps: [Step]) {
    self.steps = steps
  }

  public init(steps: Step...) {
    self.steps = steps
  }

  public func onFinish(block: FinishBlock) -> Self {
    guard case .Queued = state else { print("Cannot modify flow after starting") ; return self }
    _onFinish = block
    return self
  }

  public func onError(block: ErrorBlock) -> Self {
    guard case .Queued = state else { print("Cannot modify flow after starting") ; return self }
    _onError = block
    return self
  }

  public func onCancel(block: CancelBlock) -> Self {
    guard case .Queued = state else { print("Cannot modify flow after starting") ; return self }
    _onCancel = block
    return self
  }

  public func start() {
    guard case .Queued = state else { print("Cannot start flow twice") ; return }

    if !steps.isEmpty {
      _state = .Running(Void)
      let step = steps.first
      steps.removeFirst()
      step?.runStep(stepFlowImplementor: self, previousResult: nil)
    } else {
      print("No steps to run")
    }
  }

  public func cancel() {
    dispatch_barrier_sync(syncQueue) {
      self.steps.removeAll()
      self._state = .Canceled
    }
    dispatch_async(dispatch_get_main_queue()) {
      guard let cancelBlock = self._onCancel else {
        self._onFinish(self.state)
        return
      }
      cancelBlock()
      self._onCancel = nil
    }
  }

  deinit {
    print("Will De Init Flow Object")
  }
}

extension Flow: StepFlow {

  public func finish<T>(result: T) {
    guard case .Running = state else {

      print("Step finished but flow will be interrupted due to state being : \(state) ")

      return
    }
    guard !steps.isEmpty else {
      dispatch_barrier_sync(syncQueue) {
        self._state = .Finished(result)
      }
      dispatch_async(dispatch_get_main_queue()) {
        self._onFinish(self.state)
      }
      return
    }
    var step: Step?
    dispatch_barrier_sync(syncQueue) {
      self._state = .Running(result)
      step = self.steps.first
      self.steps.removeFirst()
    }
    step?.runStep(stepFlowImplementor: self, previousResult: result)
  }

  public func finish(error: ErrorType) {
    dispatch_barrier_sync(syncQueue) {
      self.steps.removeAll()
      self._state = .Failed(error)
    }
    dispatch_async(dispatch_get_main_queue()) {
      guard let errorBlock = self._onError else {
        self._onFinish(self.state)
        return
      }
      errorBlock(error)
      self._onError = nil
    }
  }
}
