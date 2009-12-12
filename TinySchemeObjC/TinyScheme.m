//
//  TinyScheme.m
//  TinySchemeObjC
//
//  Created by Dmitry Chestnykh on 07.12.09.
//  Copyright 2009 Coding Robots. All rights reserved.
//

#import "TinyScheme.h"
#import <ObjC/runtime.h>

@interface TinyScheme ()
@property(retain) NSMutableDictionary *registeredObjects;
- (id)initSchemeWithSafeMode:(BOOL)safeMode;
- (pointer)objCTypeToSchemeType:(id)obj;
- (id)schemeTypeToObjCType:(pointer)ptr;
- (void)registerClass:(id)object withName:(NSString *)name;
@end

// 
// Wrapper for Objective-C Class for adding it into registeredObjects
//
@interface TSClassWrapper : NSObject
{
   NSValue *value;
}
+ (TSClassWrapper *)wrapperWithClass:(Class)klass;
@property(retain) NSValue *value;
@end

@implementation TSClassWrapper
@synthesize value;

+ (BOOL)isClassWrapper 
{
  return YES;
}

+ (TSClassWrapper *)wrapperWithClass:(Class)klass
{
  TSClassWrapper *wrapper = [[TSClassWrapper alloc] init];
  wrapper.value = [NSValue valueWithPointer:klass];
  return wrapper;
}

- (Class)unwrapClass
{
  return (Class)[self.value pointerValue];
}

@end

#define IsNull(x) (x == nil || x == (id)[NSNull null]) 

NSString *TinySchemeException = @"TinySchemeException";

static TinyScheme *sharedInstance;

// Send message to object
//
// (objc-send object "method:Name:" arg1 arg2)
//
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

  if (!sig)
    [NSException raise:TinySchemeException 
                 format:@"Method ``%@'' not found in ``%@''", selName, object];

  NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
  [inv setTarget:object];
  [inv setSelector:selector];
  
  pointer curArgs = sc->vptr->pair_cdr(args);
  for (int i = 2; i < [sig numberOfArguments]; i++) {
    curArgs = sc->vptr->pair_cdr(curArgs);
    id argObj = [ts schemeTypeToObjCType:sc->vptr->pair_car(curArgs)];
    // Handle types
    const char *argType = [sig getArgumentTypeAtIndex:i];
    if (strcmp(argType, @encode(id)) == 0) {
      [inv setArgument:&argObj atIndex:i];
    }
    else if (strcmp(argType, @encode(char)) == 0) {
      char a = [argObj charValue];
      [inv setArgument:&a atIndex:i];
    }
    else if (strcmp(argType, @encode(int)) == 0) {
      int a = [argObj intValue];
      [inv setArgument:&a atIndex:i];
    }
    else if (strcmp(argType, @encode(unsigned int)) == 0) {
      unsigned int a = [argObj unsignedIntValue];
      [inv setArgument:&a atIndex:i];
    }
    else if (strcmp(argType, @encode(long)) == 0) {
      long a = [argObj longValue];
      [inv setArgument:&a atIndex:i];
    }
    else if (strcmp(argType, @encode(unsigned long)) == 0) {
      unsigned long a = [argObj unsignedLongValue];
      [inv setArgument:&a atIndex:i];
    }
    else if (strcmp(argType, @encode(float)) == 0) {
      float a = [argObj floatValue];
      [inv setArgument:&a atIndex:i];
    }
    else if (strcmp(argType, @encode(double)) == 0) {
      double a = [argObj doubleValue];
      [inv setArgument:&a atIndex:i];
    }
    else
      [NSException raise:TinySchemeException
                   format:@"Passing type ``%s''to objects is not supported",
                    argType];
  }
  [inv retainArguments];
  [inv invoke];

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

// Register and return Class
//
// (objc-class "ClassName")
//
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

// Output arguments with NSLog
//
// (log arg1 arg2 arg3)
//
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


// Invokes Scheme function from ObjC method
id invokeMethod(id self, SEL _cmd, ...)
{
  TinyScheme *ts = sharedInstance;
  scheme *sc = [sharedInstance schemePtr];
  NSString *selName = NSStringFromSelector(_cmd);
  
  Method method = class_getInstanceMethod([self class], _cmd);
  unsigned argNum = method_getNumberOfArguments(method);
  
  va_list list;
  char argType[10];
  va_start(list, _cmd);
  pointer scArgs = sc->NIL;
  
  for(int i = 2; i < argNum; i++) {
    method_getArgumentType(method, i, argType, 10);
    pointer curArg;
    if (strcmp(argType, @encode(void)) == 0) { 
      curArg = sc->NIL;
    } else if (strcmp(argType, @encode(id)) == 0) {
      curArg = [ts objCTypeToSchemeType:va_arg(list, id)];
    } else {
      // C types
      if (strcmp(argType, @encode(char)) == 0)
        curArg = sc->vptr->mk_integer(sc, va_arg(list, char));
      else if (strcmp(argType, @encode(int)) == 0)
        curArg = sc->vptr->mk_integer(sc, va_arg(list, int));
      else if (strcmp(argType, @encode(unsigned int)) == 0)
        curArg = sc->vptr->mk_integer(sc, va_arg(list, unsigned int));
      else if (strcmp(argType, @encode(long)) == 0)
        curArg = sc->vptr->mk_integer(sc, va_arg(list, long));
      else if (strcmp(argType, @encode(unsigned long)) == 0)
        curArg = sc->vptr->mk_integer(sc, va_arg(list, unsigned long));
      else if (strcmp(argType, @encode(float)) == 0)
        curArg = sc->vptr->mk_real(sc, va_arg(list, float));
      else if (strcmp(argType, @encode(double)) == 0)
        curArg = sc->vptr->mk_real(sc, va_arg(list, double));
    }
    scArgs = _cons(sc, curArg, scArgs, 1);
  }
  
  NSValue *funcPtr = [[sharedInstance registeredMethods] objectForKey:selName];
  if (IsNull(funcPtr)) {
    [NSException raise:TinySchemeException 
                 format:@"Selector %@ is not registered", selName];
  }
  pointer tmp = sc->dump; // save current dump, because sheme_call resets it
  scheme_call(sc, (pointer)[funcPtr pointerValue], scArgs);
  sc->dump = tmp; // restore dump
  return [ts schemeTypeToObjCType:sc->value];
}

// Add method to class
//
// (objc-add-method class "method:name" "types" function)
//
pointer ts_objc_add_method(scheme *sc, pointer args)
{
  TinyScheme *ts = (TinyScheme *)sc->ext_data;
  if (![ts shared])
    [NSException raise:TinySchemeException 
                 format:@"Adding methods is only supported for "
                          "shared instances of TinyScheme"];

  if (args == sc->NIL)
    [NSException raise:TinySchemeException 
                 format:@"No arguments to objc-add-method"];
  pointer nextArg = args;
  Class klass = [ts schemeTypeToObjCType:sc->vptr->pair_car(nextArg)];
  nextArg =  sc->vptr->pair_cdr(nextArg);
  if (!klass)
    [NSException raise:TinySchemeException 
                 format:@"No class found for objc-add-method"];
  NSString *methodName = [ts schemeTypeToObjCType:sc->vptr->pair_car(nextArg)];
  nextArg =  sc->vptr->pair_cdr(nextArg);
  if (IsNull(methodName))
    [NSException raise:TinySchemeException 
                 format:@"No method name in arguments for objc-add-method"];

  NSString *types = [ts schemeTypeToObjCType:sc->vptr->pair_car(nextArg)];
  nextArg =  sc->vptr->pair_cdr(nextArg);
  if (IsNull(types))
    [NSException raise:TinySchemeException 
                 format:@"No types string in arguments for objc-add-method"];
 
  pointer func = sc->vptr->pair_car(nextArg);
  // Assign func to some generated symbol to prevent it from being collected
  // by Scheme's gc
  sc->vptr->scheme_define(sc, sc->envir, sc->vptr->gensym(sc), func);

  NSValue *funcPtr = [NSValue valueWithPointer:func];
     
  [[ts registeredMethods] setObject:funcPtr forKey:methodName];
  class_addMethod(klass, NSSelectorFromString(methodName), (IMP)invokeMethod,
                  [types UTF8String]);
  
  return sc->T;
}

// Allocates new class (requires subsequent call to objc-register-class)
// 
// (objc-alloc-class superclass "ClassName") 
//
// Returns class name
//
pointer ts_objc_alloc_class(scheme *sc, pointer args)
{
  TinyScheme *ts = (TinyScheme *)sc->ext_data;
  if (args == sc->NIL)
    [NSException raise:TinySchemeException 
                 format:@"No arguments to objc-alloc-class"];
  Class superclass = [ts schemeTypeToObjCType:sc->vptr->pair_car(args)];
  if (IsNull(superclass))
    [NSException raise:TinySchemeException 
                 format:@"Undefined superclass for objc-alloc-class"];
  NSString *className = [ts schemeTypeToObjCType:
                          sc->vptr->pair_car(sc->vptr->pair_cdr(args))];
  
  Class klass = objc_allocateClassPair(superclass, [className UTF8String], 0);
  if (klass == Nil)
    [NSException raise:TinySchemeException 
                 format:@"objc-alloc-class: Cannot allocate class %@", className];
  [ts registerClass:klass withName:className];
  return sc->vptr->mk_symbol(sc, [className UTF8String]);
}

// Registers class with runtime.
// Call this after objc-class-alloc and adding methods to make class available
//
// (objc-register-class class)
//
pointer ts_objc_register_class(scheme *sc, pointer args)
{
  TinyScheme *ts = (TinyScheme *)sc->ext_data;
  if (args == sc->NIL)
    [NSException raise:TinySchemeException 
                 format:@"No arguments to objc-register-class"];
  Class klass = [ts schemeTypeToObjCType:sc->vptr->pair_car(args)];
  
  NSString *className = nil;
  objc_registerClassPair(klass);
  return sc->T;
}


// Raise exception
//
// (error "description")
//
pointer ts_error(scheme *sc, pointer args) 
{  
  TinyScheme *ts = (TinyScheme *)sc->ext_data;
  NSMutableString *arguments = [[NSMutableString alloc] init];
  while (args != sc->NIL) {
    id a = [ts schemeTypeToObjCType:sc->vptr->pair_car(args)];
    if (a)
      [arguments appendFormat:@"%@", a];
    args = sc->vptr->pair_cdr(args);
  }
  // Reset interpreter
  sc->op = (int)sc->NIL;
  sc->retcode = 0;
  sc->loadport->_flag = 16384; // T_ATOM 16384 -- for gc
  [NSException raise:TinySchemeException 
             format:@"Scheme error: (%@)", arguments];
}

@implementation TinyScheme
@synthesize registeredObjects=registeredObjects_;
@synthesize registeredMethods=registeredMethods_;
@synthesize shared=isShared_;
@synthesize schemePtr=sc_;

+ (TinyScheme *)sharedTinyScheme
{
  @synchronized(self) {
    if (sharedInstance == nil) {
      sharedInstance = [[TinyScheme alloc] init];
      sharedInstance.shared = YES;
    }
  }
  return sharedInstance;
}

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
  isInSaveMode_ = safeMode;
  registeredObjects_ = [[NSMutableDictionary alloc] init];
  registeredMethods_ = [[NSMutableDictionary alloc] init];
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
    sc_->vptr->scheme_define(
         sc_, 
         sc_->global_env, 
         sc_->vptr->mk_symbol(sc_, "objc-add-method"),
         sc_->vptr->mk_foreign_func(sc_, ts_objc_add_method));
    sc_->vptr->scheme_define(
         sc_, 
         sc_->global_env, 
         sc_->vptr->mk_symbol(sc_, "objc-alloc-class"),
         sc_->vptr->mk_foreign_func(sc_, ts_objc_alloc_class));
    sc_->vptr->scheme_define(
         sc_, 
         sc_->global_env, 
         sc_->vptr->mk_symbol(sc_, "objc-register-class"),
         sc_->vptr->mk_foreign_func(sc_, ts_objc_register_class));
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
  [registeredMethods_ release];
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
- (void)registerClass:(Class)klass withName:(NSString *)name 
{
  //[[NSGarbageCollector defaultCollector]
  //  disableCollectorForPointer:klass];
  [registeredObjects_ setObject:[TSClassWrapper wrapperWithClass:klass] 
                      forKey:name];
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
  else if (sc_->vptr->is_symbol(ptr)) {
    id obj =  [registeredObjects_ objectForKey:
      [NSString stringWithUTF8String:sc_->vptr->symname(ptr)]];
    if ([obj isKindOfClass:[TSClassWrapper class]]) // unwrap Class
      return [obj unwrapClass];
    else
      return obj;
  }
  else if (sc_->vptr->is_integer(ptr))
    return [NSNumber numberWithInt:sc_->vptr->ivalue(ptr)];
  else if (sc_->vptr->is_real(ptr))
    return [NSNumber numberWithDouble:sc_->vptr->rvalue(ptr)];
  else if (ptr == sc_->NIL)
    return [NSNull null];
  else
    [NSException raise:TinySchemeException format:@"Unknown scheme type"];
}

- (void)releaseRegisteredObjects;
{
  [registeredObjects_ removeAllObjects];
  if (!isInSaveMode_) // readd self
    [self registerObject:self withName:@"current-objc-interface"];
}

@end
