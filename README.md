# Step Flow
<p align="center"><img src="icon.png" alt="StepFlow Logo"></p>
[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
![Platforms](https://img.shields.io/cocoapods/p/StepFlow.svg?style=flat)

![Podspec](https://img.shields.io/cocoapods/v/StepFlow.svg)
[![License](https://img.shields.io/cocoapods/l/StepFlow.svg)](https://github.com/Swiftification/StepFlow/master/LICENSE)

[![Build Status](https://travis-ci.org/Swiftification/StepFlow.svg?branch=master)](https://travis-ci.org/JARMourato/StepFlow)
[![codecov.io](https://codecov.io/github/Swiftification/StepFlow/coverage.svg?branch=master)](https://codecov.io/github/Swiftification/StepFlow?branch=master)
[![codebeat badge](https://codebeat.co/badges/b1709704-b1b6-40fa-a38f-0962f72aa264)](https://codebeat.co/projects/github-com-jarmourato-stepflow)

The purpose of StepFlow is to provide a simple way to layout a stream of macro-steps to execute and then run them. There are plenty good open source libraries that can be used to create Queues, or perform small tasks (either serially or concurrently), etc. So, in no way is this meant to replace them. Maybe in one step you want o use library X to download all images from some url and in another you want to use library Y to Queue image processing.

### Note:

StepFlow requires swift 3.0 from version 2.0.0 onwards. If needed, use version 1.1.0 for swift 2.3 and version 1.0.0 for swift 2.2

## Installation

StepFlow is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'StepFlow'
```

## Usage

#### Basic setup

Just create the steps and use Flow to run them:

```swift

let stepOne = Step { stepFlow, previousResult in
  // previousResult in the first step is nil
  // code to be executed on Step 1
  stepFlow.finish(result: stepOneResult)
}

let stepTwo = Step { stepFlow, previousResult in
  // previousResult in the second step is the result of step 1
  // The error can be anything as long as it conforms to the ErrorType protocol
  // code to be executed on Step 2
  stepFlow.finish(error: someError)
}

Flow(steps: stepOne,stepTwo).start()

```
In the step closure, don't forget to finish the step either with some result or some error. Or else, the flow will halt there. 

#### Handle Closures

StepFlow provides closures you can use to be run when the flow finishes, ends with error or is cancelled. All handle closures are run on the main thread. 

##### Finish 

```swift

Flow(steps: stepOne,stepTwo).onFinish{ finishState in
  // code to be run after all steps finish
}.start()

```

##### Error
If you finish the step with error, the flow will end. 

```swift

Flow(steps: stepOne,stepTwo).onError{ error in
  // code to be executed if a step failed. The error will be sent here
}.onFinish{ finishState in
  // If one step is finished with error. This block will not be executed.
  // Unless, no onError closure is provided, in which case the Flow will 
  // default to this closure with finishState = .Failed(let error)
}.start()

```

##### Cancel

If the flow is canceled. 

```swift

let f = Flow(steps: stepOne,stepTwo).onCancel{ 
  // code to be executed if the flow is canceled.
}.onFinish{ finishState in
  // If the flow is canceled. This block will not be executed.
  // Unless, no onCancel closure is provided, in which case the Flow will 
  // default to this closure with finishState = .Canceled
}

f.start()
f.cancel()

```

#### Async Steps

It is not the purpose of StepFlow to provide a way of run code asynchronously. As stated above, there are plenty of other good options, well documented, which you can use alongside with StepFlow. Nonetheless, you can run a step in a background thread by setting it on when creating a step.

```swift

let stepAsync = Step(onBackgroundThread : true) { stepFlow, previousResult in
  // previousResult in the first step is nil
  // code to be executed on a background thread
  stepFlow.finish(result: stepOneResult)
}

```

By default all steps are run on the calling thread. 

## License

Step Flow is available under the MIT license. See the LICENSE file for more info.
