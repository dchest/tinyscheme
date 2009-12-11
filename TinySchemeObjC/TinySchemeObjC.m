#import <Foundation/Foundation.h>
#import "TinyScheme.h"

@interface Test : NSObject {
  int cnt;
}
- (void)displayObject:(id)s;
- (BOOL)hasBool;
@end

@implementation Test

- (void)displayObject:(id)s
{
  NSLog(@"Test says [%d]: %@", cnt++, s);
}

- (void)testArgumentsWithBool:(BOOL)b andString:(NSString *)s
{
  if (b)
    NSLog(@"b=YES, s=%@", s);
  else
    NSLog(@"b=NO, s=%@", s);
}

- (NSString *)testArgumentsWithFloat:(float)f andInt:(int)i
{
  return [NSString stringWithFormat:@"float=%f int=%d", f, i];
}


- (BOOL)hasBool
{
  return NO;
}

@end



//
// NOTE! Paths are currently hardcoded, change them to yours.
//

int main (int argc, const char * argv[]) 
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  TinyScheme *ts = [TinyScheme sharedTinyScheme];
  //[[TinyScheme alloc] init];
  if (![ts loadFileWithPath:@"/Users/dmitry/Projects/tinyscheme/init.scm"])
    NSLog(@"cannot load init.scm");
/*
  @try {
    [ts loadString:@""
      " (define (logme x)  "
      "   (log x))         "
      "                    "
      " (log-me \"test\")) " // <-- notice the error, calling log-me
    ];
  }
  @catch (NSException *e) {
    NSLog(@"(This is *intentional*! --> Successfuly cought code with errors. "
           "The exception was: %@ reason: ``%@'')", [e name], [e reason]);
  }
*/
  // Expose some objects to scheme
  NSNumber *magicNumber = [NSNumber numberWithInt:42];
  [ts registerObject:magicNumber withName:@"magicNumber"];

  if (![ts loadFileWithPath:@"/Users/dmitry/Projects/tinyscheme/TinySchemeObjC/objc.scm"])
    NSLog(@"cannot load objc.scm");
  
  if (![ts loadFileWithPath:@"/Users/dmitry/Projects/tinyscheme/TinySchemeObjC/test.scm"])
    NSLog(@"cannot load test.scm");
/*
  [ts loadString:@""
    " (logme \"Finished\")  " // <-- remember logme from above? It's still defined
  ];
*/
  [ts release];
  [pool drain];
  return 0;
}
