NWLogging
=========

*A minimalistic logging framework for Cocoa.*


<a name="NWL_About"></a>
About
-----
NWLogging is a Cocoa logging framework that provides logging functions similar to NSLog. What makes it particularly useful is the flexibility with which logs can be filtered and directed to different outputs, both in source and at runtime. This makes NWLogging a useful tool for debugging and error reporting, without the log spam of a growing project.


<a name="NWL_GettingStarted"></a>
Getting Started
---------------
You can get started with NWLogging in your Cocoa or Cocoa Touch application in just a few steps. Say you want to log when your app starts in the AppDelegate.m file:

1. Add NWLCore.h and NWLCore.m to your app target.
2. Include NWLCore.h at the top of your source file (AppDelegate.m in this case):

        #include "NWLCore.h"
    
3. Add the log line to your code (didFinishLaunching: in this case):

        NWLog(@"Application did finish launching: %@", self);
        
4. Start your app (in debug mode) and keep an eye on the console output:

        [12:34:56.789000 AppDelegate.m:123] Application did finish launching: <AppDelegate: 0xd80da1>

This is just a minimal setup to demonstrate the necessary steps to get NWLogging to run. In general it is recommended to link with `libNWLogging.a` en use precompiled headers to include `NWLogging.h`. See the [Project Setup](#NWL_ProjectSetup) section for detailed instructions.


<a name="NWL_Features"></a>
Features
--------
+ Logging functionality similar to NSLog.
+ Log filtering based on target, file, function, and custom tags.
+ Log output to console, file, and custom printers.
+ Alternative log actions like pause debugger or throw exception.
+ Configuration both statically from source code and in the debugger at runtime.
+ Easy to migrate from NSLog: NWLog == NSLog (kinda)
+ Supports pure C and C++ projects.
+ Concurrent, but free of locking.
+ No heap allocation if not logging.


<a name="NWL_ProjectSetup"></a>
Project setup
-------------
NWLogging can be added to your project either by linking with a static library or by including the sources needed. The core functionality is kept in a single file (`NWLCore.c`), which you can simply add (together with `NWLCore.h`) to your project and get started. To avoid collision with the uses in other projects, it is recommended to not include the source, but instead link with the NWLogging static library.

There are many ways to link with NWLogging in Xcode. You can for example run the NWLoggingUniversal target, which outputs a `libNWLogging.a` in the project root. By simply dragging this file into your application sources, Xcode will do all the configuration for you. Alternatively you can add the NWLogging project to your workspace and link with `libNWLogging.a` directly.

Next, you should add the library header files to your project. Again, there are severa ways to to this. For example by adding all header files to your application's sources. A convenient way to include the main `NWLogging.h` header in your project, is by referencing it in your Prefix Header file (`.pch`). For example:

    #ifdef __OBJC__
        #import <UIKit/UIKit.h>
        #import <Foundation/Foundation.h>
    #endif

    #import "NWLogging.h"

NWLogging is now ready for use in the Debug configuration. It is however highly recommended to set the name of the target. This allows NWLogging to add this to the log output, and provide the `lib` filter property. This is particularly useful when multiple targets use NWLogging, and you want to configure them separately.

You can set the `lib` property by defining the NWL_LIB preprocessor variable, for example by adding `NWL_LIB=$(TARGET_NAME)` to the 'Preprocessor Macros' parameter in your target's build settings:

     Debug    DEBUG=1 NWL_LIB=$(TARGET_NAME)

By default NWLogging is disabled in non-DEBUG configurations, like Release. To ensure logging in other configurations you must explicitly set NWL_LIB in the preprocessor:

     Release  NWL_LIB=$(TARGET_NAME)

To see if NWLogging has been set up properly, add the following in your application main or launch method:

    NWLog(@"Works like a charm");
        
When run, this should output something like:

    [12:34:56.789000 MyApp main.c:012] Works like a charm
    
Having completed the setup, it's time for some action in the [How to](#NWL_HowTo) section. If you'd like a more conceptual understanding, take a look in the [Concepts](#NWL_Concepts) section.


<a name="NWL_HowTo"></a>
How to
------
#### How to log some text to the console output?

    NWLog(@"some text");
    
#### How to log debug text that can be filtered out later on?

    NWLogDbug(@"debug text that is not shown");
    NWLPrintDbug();  // turn on printing of 'dbug' tag
    NWLogDbug(@"debug text that is printed");
    
#### How to log a warning text?

    NWLogWarn(@"warning text!");
    
#### How to log some warning text when a condition fails?
    
    NWLogWarnIfNot(index < length, @"Expected index (%i) to be less than length (%i)", index, length);

#### How to print text of the 'info' level?

    NWLPrintInfo();  // turn on 'info' tag
    NWLogInfo(@"some info");

#### How to see which filters and printers are active?

    NWLDump();


<!--
<a name="NWL_Concepts"></a>
Concepts
--------
-->


<a name="NWL_FAQ"></a>
FAQ
---
#### Why does my log message not appear in the output?

Assuming your console is properly set up and *does show stderr* output, there are several reasons a line is not displayed:

1. You're logging on a tag that is not active. For example, to log on the 'info' tag, you need to activate it first:

        NWLPrintInfo();  // activate all logging of info tag
        NWLogInfo(@"This line should be logged");
    
    If you want to see which filters are active, use the `NWLDump()` method, which should give you something like:
    
        About NWLogging
           #printers:1
           action:print tag:warn
           action:print tag:info
           time-offset:0.000000

    Optionally, you can replace your `NWLogInfo(..)` call with `NWLog(..)`, without the 'info'. `NWLog` always logs, ignoring all filters, just like `NSLog` does.
    
2. Another cause might be that the console (stderr) printer is not active. Activate the default printer with:

        NWLRestoreDefaultPrinters();
        
3. You might run a complex configuration of filters and have no clue which filter does what. Reset all filter actions using:

        NWLRestoreDefaultActions();
                
4. Possibly you didn't do all necessary setup. If you run in Release configuration, you need to explicitly define NWL_LIB. Make sure you followed the steps described in the [Project Setup](#NWL_ProjectSetup) section.

    Still not working? Drop me a line: leonardvandriel at gmail.


#### Which log levels are there?

Technically, NWLogging does not have log levels. Instead, it offers *tags*, which offer the same functionality as levels, but are more flexible. There are three default tags (read levels): warn, info, dbug, but you can use any tag you want. For example, if you want to do very fine grained logging on the trace 'level', use:

    NWLogTag(trace, @"Lots of stuff happening here");
    
You can activate the trace logs with:

    NWLPrintTag("trace");
    
Note that tags don't have any natural ordering. Activating the 'dbug' tag does *not* automatically activate the 'info' tag.


<a name="NWL_License"></a>
License
-------
NWLogging is licensed under the terms of the BSD 2-Clause License, see the included LICENSE file.


<a name="NWL_Authors"></a>
Authors
-------
- [Noodlewerk](http://www.noodlewerk.com/)
- [Leonard van Driel](http://www.leonardvandriel.nl/)