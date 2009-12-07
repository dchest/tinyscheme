#import <Foundation/Foundation.h>
#import "TinyScheme.h"

@interface Test : NSObject {
  int cnt;
}
- (void)displayObject:(id)s;
@end

@implementation Test

- (void)displayObject:(id)s
{
  NSLog(@"Test says [%d]: %@", cnt++, s);
}

@end


int main (int argc, const char * argv[]) 
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

  TinyScheme *ts = [[TinyScheme alloc] init];
  [ts loadFileWithPath:@"/Users/dmitry/Projects/tinyscheme/init.scm"];

  //Test *test = [[Test alloc] init];
  //[ts registerObject:test withName:@"test"];
  
  if (![ts loadFileWithPath:@"/Users/dmitry/Projects/tinyscheme/TinySchemeObjC/test.scm"])
    NSLog(@"cannot load test.scm");

  //[test release];
  [ts release];
  [pool drain];
  return 0;
}
