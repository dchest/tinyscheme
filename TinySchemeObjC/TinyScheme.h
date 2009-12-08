//
//  TinyScheme.h
//  TinySchemeObjC
//
//  Created by Dmitry Chestnykh on 07.12.09.
//  Copyright 2009 Coding Robots. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define USE_INTERFACE 1
#import "scheme.h"
#import "scheme-private.h"

@interface TinyScheme : NSObject {
  scheme *sc_;
  NSMutableDictionary *registeredObjects_;
}
- (id)init;
// Safe mode disables introspection, classes and creation of new objects
// (no 'current-objc-interface, objc-class defined)
- (id)initInSafeMode;

- (BOOL)loadFileWithURL:(NSURL *)url;
- (BOOL)loadFileWithPath:(NSString *)path;
- (void)loadString:(NSString *)string;
- (void)registerObject:(id)object withName:(NSString *)name;

// Use this instead of registeredObjects to inspect registered objects in Scheme
@property(readonly, retain) NSDictionary *registeredObjectsCopy;


@end
