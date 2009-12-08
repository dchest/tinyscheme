//
//  TinyScheme.m
//  TinySchemeObjC
//
//  Created by Dmitry Chestnykh on 07.12.09.
//  Copyright 2009 Coding Robots. All rights reserved.
//

#import "TinyScheme.h"

@interface TinyScheme ()
@property(retain) NSMutableDictionary *registeredObjects;
- (id)initSchemeWithSafeMode:(BOOL)safeMode;
- (pointer)objCTypeToSchemeType:(id)obj;
- (id)schemeTypeToObjCType:(pointer)ptr;
- (void)registerClass:(id)object withName:(NSString *)name;
@end

#define SCI sc->vptr
#define IsNull(x) (x == nil || x == (id)[NSNull null]) 

NSString *TinySchemeException = @"TinySchemeException";

pointer ts_objc_send(scheme *sc, pointer args) 
{
  TinyScheme *ts = (TinyScheme *)sc->ext_data;
  NSString *objc_id = NULL, *objc_sel = NULL; 

  if (args == sc->NIL)
    [NSException raise:TinySchemeException format:@"No arguments to objc-send"];
  
  id object = [ts schemeTypeToObjCType:sc->vptr->pair_car(args)];
  if (IsNull(object))
      [NSException raise:TinySchemeException format:@"No object found"];

  NSString *selName = [ts schemeTypeToObjCType:
                        sc->vptr->pair_car(sc->vptr->pair_cdr(args))];
  
  if (IsNull(selName))
    [NSException raise:TinySchemeException format:@"No selector in arguments"];
  
  
  SEL selector = NSSelectorFromString(selName);
  
  NSMethodSignature *sig = 
    [object methodSignatureForSelector:selector];

  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
  [inv setTarget:object];
  [inv setSelector:selector];
  
  pointer curarg = sc->vptr->pair_cdr(args);
  for (int i = 2; i < [sig numberOfArguments]; i++) {
    curarg = sc->vptr->pair_cdr(curarg);
    id arg = [ts schemeTypeToObjCType:sc->vptr->pair_car(curarg)];
    [inv setArgument:&arg atIndex:i];
  }
  [inv retainArguments];
  [inv invoke];
    
  //NSLog(@"## %@ -> %s", selName, [sig methodReturnType]);
  
  if (strcmp([sig methodReturnType], @encode(void)) == 0) { 
    // void
    return sc->NIL;
  } else if (strcmp([sig methodReturnType], @encode(id)) == 0) {
    // objects
    id result = nil;
    [inv getReturnValue:&result];
    return [ts objCTypeToSchemeType:result];
  } else {
    // C types
    NSUInteger length = [[inv methodSignature] methodReturnLength];
    const char *returnType = [sig methodReturnType];
    void *buffer = (void *)malloc(length);
    [inv getReturnValue:buffer];
    pointer r;
    if (strcmp(returnType, @encode(char)) == 0)
      r = sc->vptr->mk_integer(sc, *(char *)buffer);
    else if (strcmp(returnType, @encode(int)) == 0)
      r = sc->vptr->mk_integer(sc, *(int *)buffer);
    else if (strcmp(returnType, @encode(unsigned int)) == 0)
      r = sc->vptr->mk_integer(sc, *(unsigned int *)buffer);
    else if (strcmp(returnType, @encode(long)) == 0)
      r = sc->vptr->mk_integer(sc, *(long *)buffer);
    else if (strcmp(returnType, @encode(unsigned long)) == 0)
      r = sc->vptr->mk_integer(sc, *(unsigned long *)buffer);
    else if (strcmp(returnType, @encode(float)) == 0)
      r = sc->vptr->mk_real(sc, *(float *)buffer);
    else if (strcmp(returnType, @encode(double)) == 0)
      r = sc->vptr->mk_real(sc, *(double *)buffer);
    free(buffer);
    return r;
  }
  return sc->NIL;
}

pointer ts_objc_class(scheme *sc, pointer args)
{
  TinyScheme *ts = (TinyScheme *)sc->ext_data;
  if (args == sc->NIL)
    [NSException raise:TinySchemeException format:@"No arguments to objc-class"];
  if (!sc->vptr->is_string(sc->vptr->pair_car(args)))
    [NSException raise:TinySchemeException format:
      @"Argument to objc-class is not string"];
  // get class name
  char *cname = sc->vptr->string_value(sc->vptr->pair_car(args));
  NSString *cnameString = [NSString stringWithUTF8String:cname];
  [ts registerClass:NSClassFromString(cnameString) withName:cnameString];
  return sc->vptr->mk_symbol(sc, cname); // case sensitive
}

pointer ts_log(scheme *sc, pointer args)
{
  TinyScheme *ts = (TinyScheme *)sc->ext_data;
  if (args == sc->NIL)
    [NSException raise:TinySchemeException format:@"No arguments to log"];
  NSMutableString *str = [[[NSMutableString alloc] init] autorelease];
  pointer curarg = args;
  do {
    id arg = [ts schemeTypeToObjCType:sc->vptr->pair_car(curarg)];
    [str appendFormat:@"%@ ", arg];
  } while ((curarg = sc->vptr->pair_cdr(curarg)) != sc->NIL);
  NSLog(@"%@", str);
  return sc->NIL;
}

pointer ts_error(scheme *sc, pointer args) 
{
  [NSException raise:TinySchemeException format:@"Scheme error: %s", 
    sc->vptr->string_value(sc->vptr->pair_car(args))];
}

@implementation TinyScheme
@synthesize registeredObjects=registeredObjects_;

- (id)init
{
  if (![super init])
    return nil;
  [self initSchemeWithSafeMode:NO];
  return self;
}

- (id)initInSafeMode
{
  if (![super init])
    return nil;
  [self initSchemeWithSafeMode:YES];
  return self;  
}

- (id)initSchemeWithSafeMode:(BOOL)safeMode // private
{
  registeredObjects_ = [[NSMutableDictionary alloc] init];
  sc_ = scheme_init_new();
  scheme_set_external_data(sc_, self);
  sc_->vptr->scheme_define( 
       sc_, 
       sc_->global_env, 
       sc_->vptr->mk_symbol(sc_, "objc-send"),
       sc_->vptr->mk_foreign_func(sc_, ts_objc_send));
  if (!safeMode) {
    sc_->vptr->scheme_define(
         sc_, 
         sc_->global_env, 
         sc_->vptr->mk_symbol(sc_, "objc-class"),
         sc_->vptr->mk_foreign_func(sc_, ts_objc_class));
  }
  sc_->vptr->scheme_define(
       sc_, 
       sc_->global_env, 
       sc_->vptr->mk_symbol(sc_, "log"),
       sc_->vptr->mk_foreign_func(sc_, ts_log)); 
  sc_->vptr->scheme_define(
       sc_, 
       sc_->global_env, 
       sc_->vptr->mk_symbol(sc_, "error"),
       sc_->vptr->mk_foreign_func(sc_, ts_error));
  if (!safeMode)
    [self registerObject:self withName:@"current-objc-interface"];
}

- (void)dealloc
{
  [registeredObjects_ release];
  scheme_deinit(sc_);
}

- (void)finalize
{  
  scheme_deinit(sc_);
}

- (BOOL)loadFileWithURL:(NSURL *)url
{
  FILE *f = fopen([[url path] fileSystemRepresentation], "r");
  if (!f)
    return NO;
  scheme_load_file(sc_, f);
  fclose(f);
  return YES;
}

- (BOOL)loadFileWithPath:(NSString *)path
{
  return [self loadFileWithURL:[NSURL fileURLWithPath:path]];
}

- (void)loadString:(NSString *)string
{
  scheme_load_string(sc_, [string UTF8String]);
}

// Private method similar to registerObject, but preserves case
- (void)registerClass:(id)object withName:(NSString *)name 
{
  [registeredObjects_ setObject:object forKey:name];
}

- (void)registerObject:(id)object withName:(NSString *)name
{
  [registeredObjects_ setObject:object forKey:[name lowercaseString]];
}

- (NSDictionary *)registeredObjectsCopy
{
  return [registeredObjects_ copy];
}

- (pointer)objCTypeToSchemeType:(id)obj
{
  if (obj == nil || obj == [NSNull null])
    return sc_->NIL;
  else if ([obj isKindOfClass:[NSString class]])
    return sc_->vptr->mk_string(sc_, [obj UTF8String]);
  else if ([obj isKindOfClass:[NSNumber class]]) {
    if (strcmp([obj objCType], @encode(int)) == 0
       || strcmp([obj objCType], @encode(unsigned int)) == 0
       || strcmp([obj objCType], @encode(long)) == 0
       || strcmp([obj objCType], @encode(unsigned long)) == 0)
      return sc_->vptr->mk_integer(sc_, [obj longValue]);
    else if (strcmp([obj objCType], @encode(double)) == 0)
      return sc_->vptr->mk_real(sc_, [obj doubleValue]);
    else
      [NSException raise:TinySchemeException format:
        @"Cannot convert value of number type %s to scheme type", 
        [obj objCType]];
  }
  else {
    // This is just some object, register it and convert to symbol

    // If this object is already registered, get its name
    // FIXME: not efficient
    NSString *name = nil;
    for (NSString *key in registeredObjects_) {
      if ([[registeredObjects_ objectForKey:key] isEqual:obj]) {
        name = [key copy];
        break;
      }
    }
    
    // If object is not registered, create a new name from hash
    if (!name) {
      name = [NSString stringWithFormat:@"objc-%@-%lu",
                [obj className], (unsigned long)[obj hash]];
      [self registerObject:obj withName:name];
    }
    return sc_->vptr->mk_symbol(sc_, [[name lowercaseString] UTF8String]);
  }
  //[NSException raise:TinySchemeException format:@"Unknown type of %@", obj];
}

- (id)schemeTypeToObjCType:(pointer)ptr
{
  if (sc_->vptr->is_string(ptr))
    return [NSString stringWithUTF8String:sc_->vptr->string_value(ptr)];
  else if (sc_->vptr->is_symbol(ptr))
    return [registeredObjects_ objectForKey:
      [NSString stringWithUTF8String:sc_->vptr->symname(ptr)]];
  else if (sc_->vptr->is_integer(ptr))
    return [NSNumber numberWithInt:sc_->vptr->ivalue(ptr)];
  else if (sc_->vptr->is_real(ptr))
    return [NSNumber numberWithDouble:sc_->vptr->rvalue(ptr)];
  else if (ptr == sc_->NIL)
    return [NSNull null];
  else
    [NSException raise:TinySchemeException format:@"Unknown scheme type"];
}

@end
