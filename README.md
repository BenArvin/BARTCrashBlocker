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

## Installation
Download the latest tag and drag the `BARTCrashBlocker` folder into your Xcode project.
