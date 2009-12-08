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


int main (int argc, const char * argv[]) 
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  TinyScheme *ts = [[TinyScheme alloc] init];
  if (![ts loadFileWithPath:@"/Users/dmitry/Projects/tinyscheme/init.scm"])
    NSLog(@"cannot load init.scm");

  // Expose some objects to scheme
  NSNumber *magicNumber = [NSNumber numberWithInt:42];
  [ts registerObject:magicNumber withName:@"magicNumber"];
  
  if (![ts loadFileWithPath:@"/Users/dmitry/Projects/tinyscheme/TinySchemeObjC/test.scm"])
    NSLog(@"cannot load test.scm");

  @try {
    [ts loadString:@"(some (scheme code) with errors))"];
  }
  @catch (NSException *e) {
    NSLog(@"(Successfuly cought code with errors. This is intentional! "
           "The exception was: %@ reason: ``%@'')", [e name], [e reason]);
  }

  [ts release];
  [pool drain];
  return 0;
}
