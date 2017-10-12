# BARTCrashBlocker
## Introduction
BARTCrashBlocker is a Objective-C crash protector, implemented by runtime programming.

It provide protection for 3 kind of crash:

- unrecognized selector crash

- KVO crash
	- observer/keyPath invalid
 
 	- duplicate add/remove observer
 
 	- observer/observed target released

- container crash
	- NSString/NSMutableString

	- NSArray/NSMutableArray

	- NSDictionary/NSMutableDictionary

And also provide a flexible way to observe dealloc function of NSObject class object.

## Installation & Use
Download the latest tag and drag the `BARTCrashBlocker` folder into your Xcode project.

- use `BARTCrashBlocker.h` to load/unload specific crash blocker

- use `BARTDeallocObserver.h` to start/stop dealloc function observing