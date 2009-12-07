#import <Foundation/Foundation.h>
#import "TinyScheme.h"

int main (int argc, const char * argv[]) 
{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

  TinyScheme *tc = [[TinyScheme alloc] init];
  [tc loadFileWithPath:@"/Users/dmitry/Projects/tinyscheme/init.scm"];
  
  [tc loadString:@"(display \"this is test\")"];
  [tc test];

  [pool drain];
  return 0;
}
