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

  fileprivate var steps: [Step]
  public typealias FinishBlock = (FlowState<Any>) -> ()
  public typealias ErrorBlock = (Error) -> ()
  public typealias CancelBlock = () -> ()
  fileprivate var _onFinish: FinishBlock = { _ in }
  fileprivate var _onError: ErrorBlock?
  fileprivate var _onCancel: CancelBlock?
  fileprivate var _state: FlowState<Any> = .queued
  fileprivate let syncQueue = DispatchQueue(label: "com.flow.syncQueue", attributes: DispatchQueue.Attributes.concurrent)

  public var state: FlowState<Any> {
    var val: FlowState<Any>?
    syncQueue.sync {
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

  public func onFinish(_ block: @escaping FinishBlock) -> Self {
    guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
    _onFinish = block
    return self
  }

  public func onError(_ block: @escaping ErrorBlock) -> Self {
    guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
    _onError = block
    return self
  }

  public func onCancel(_ block: @escaping CancelBlock) -> Self {
    guard case .queued = state else { print("Cannot modify flow after starting") ; return self }
    _onCancel = block
    return self
  }

  public func start() {
    guard case .queued = state else { print("Cannot start flow twice") ; return }

    if !steps.isEmpty {
      _state = .running(Void.self)
      let step = steps.first
      steps.removeFirst()
      step?.runStep(stepFlowImplementor: self, previousResult: nil)
    } else {
      print("No steps to run")
    }
  }

  public func cancel() {
    syncQueue.sync(flags: .barrier, execute: {
      self.steps.removeAll()
      self._state = .canceled
    }) 
    DispatchQueue.main.async {
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

  public func finish<T>(_ result: T) {
    guard case .running = state else {

      print("Step finished but flow will be interrupted due to state being : \(state) ")

      return
    }
    guard !steps.isEmpty else {
      syncQueue.sync(flags: .barrier, execute: {
        self._state = .finished(result)
      }) 
      DispatchQueue.main.async {
        self._onFinish(self.state)
      }
      return
    }
    var step: Step?
    syncQueue.sync(flags: .barrier, execute: {
      self._state = .running(result)
      step = self.steps.first
      self.steps.removeFirst()
    }) 
    step?.runStep(stepFlowImplementor: self, previousResult: result)
  }

  public func finish(_ error: Error) {
    syncQueue.sync(flags: .barrier, execute: {
      self.steps.removeAll()
      self._state = .failed(error)
    }) 
    DispatchQueue.main.async {
      guard let errorBlock = self._onError else {
        self._onFinish(self.state)
        return
      }
      errorBlock(error)
      self._onError = nil
    }
  }
}
