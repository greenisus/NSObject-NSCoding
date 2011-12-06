//
//  NSObject+NSCoding.m
//  OpenStack
//
//  Created by Michael Mayo on 3/4/11.
//  The OpenStack project is provided under the Apache 2.0 license.
//

#import "NSObject+NSCoding.h"
#import <objc/runtime.h>


@implementation NSObject (NSCoding)

- (NSMutableDictionary *)propertiesForClass:(Class)klass {
    
    NSMutableDictionary *results = [[[NSMutableDictionary alloc] init] autorelease];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        
        NSString *pname = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString *pattrs = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        pattrs = [[pattrs componentsSeparatedByString:@","] objectAtIndex:0];
        pattrs = [pattrs substringFromIndex:1];
        
        [results setObject:pattrs forKey:pname];
    }
    free(properties);
    
    if ([klass superclass] != [NSObject class]) {
        [results addEntriesFromDictionary:[self propertiesForClass:[klass superclass]]];
    }
    
    return results;
}

- (NSDictionary *)properties {
    return [self propertiesForClass:[self class]];
}

- (void)autoEncodeWithCoder:(NSCoder *)coder {
    NSDictionary *properties = [self properties];
    for (NSString *key in properties) {
        NSString *type = [properties objectForKey:key];
        id value;
        unsigned long long ullValue;
        BOOL boolValue;
        float floatValue;
        double doubleValue;
        NSInteger intValue;
        unsigned long ulValue;
		long longValue;
		unsigned unsignedValue;
		short shortValue;
        NSString *className;
		
        NSMethodSignature *signature = [self methodSignatureForSelector:NSSelectorFromString(key)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:NSSelectorFromString(key)];
        [invocation setTarget:self];
        
        switch ([type characterAtIndex:0]) {
            case '@':   // object
                if ([[type componentsSeparatedByString:@"\""] count] > 1) {
                    className = [[type componentsSeparatedByString:@"\""] objectAtIndex:1];
                    Class class = NSClassFromString(className);
                    value = [self performSelector:NSSelectorFromString(key)];
					
                    // only decode if the property conforms to NSCoding
                    if([class conformsToProtocol:@protocol(NSCoding)]){
                        [coder encodeObject:value forKey:key];
                    }
                }
                break;
            case 'c':   // bool
                [invocation invoke];
                [invocation getReturnValue:&boolValue];
                [coder encodeObject:[NSNumber numberWithBool:boolValue] forKey:key];
                break;
            case 'f':   // float
                [invocation invoke];
                [invocation getReturnValue:&floatValue];
                [coder encodeObject:[NSNumber numberWithFloat:floatValue] forKey:key];
                break;
            case 'd':   // double
                [invocation invoke];
                [invocation getReturnValue:&doubleValue];
                [coder encodeObject:[NSNumber numberWithDouble:doubleValue] forKey:key];
                break;
            case 'i':   // int
                [invocation invoke];
                [invocation getReturnValue:&intValue];
                [coder encodeObject:[NSNumber numberWithInt:intValue] forKey:key];
                break;
            case 'L':   // unsigned long
                [invocation invoke];
                [invocation getReturnValue:&ulValue];
                [coder encodeObject:[NSNumber numberWithUnsignedLong:ulValue] forKey:key];
                break;
            case 'Q':   // unsigned long long
                [invocation invoke];
                [invocation getReturnValue:&ullValue];
                [coder encodeObject:[NSNumber numberWithUnsignedLongLong:ullValue] forKey:key];
                break;
            case 'l':   // long
                [invocation invoke];
                [invocation getReturnValue:&longValue];
                [coder encodeObject:[NSNumber numberWithLong:longValue] forKey:key];
                break;
            case 's':   // short
                [invocation invoke];
                [invocation getReturnValue:&shortValue];
                [coder encodeObject:[NSNumber numberWithShort:shortValue] forKey:key];
                break;
            case 'I':   // unsigned
                [invocation invoke];
                [invocation getReturnValue:&unsignedValue];
                [coder encodeObject:[NSNumber numberWithUnsignedInt:unsignedValue] forKey:key];
                break;
            default:
                break;
        }        
    }
}

- (void)autoDecode:(NSCoder *)coder {
    NSDictionary *properties = [self properties];
    for (NSString *key in properties) {
        NSString *type = [properties objectForKey:key];
        id value;
        NSNumber *number;
        unsigned int addr;
        NSInteger i;
        CGFloat f;
        BOOL b;
        double d;
        unsigned long ul;
        unsigned long long ull;
		long longValue;
		unsigned unsignedValue;
		short shortValue;
        Ivar ivar;
        double *varIndex;
        
        NSString *className;
        
        switch ([type characterAtIndex:0]) {
            case '@':   // object
                if ([[type componentsSeparatedByString:@"\""] count] > 1) {
                    className = [[type componentsSeparatedByString:@"\""] objectAtIndex:1];                    
                    Class class = NSClassFromString(className);
                    // only decode if the property conforms to NSCoding
                    if ([class conformsToProtocol:@protocol(NSCoding )]){
                        value = [[coder decodeObjectForKey:key] retain];
                        addr = (NSInteger)&value;
                        object_setInstanceVariable(self, [key UTF8String], *(id**)addr);
                    }
                }
                break;
            case 'c':   // bool
                number = [coder decodeObjectForKey:key];                
                b = [number boolValue];
                addr = (NSInteger)&b;
                object_setInstanceVariable(self, [key UTF8String], *(NSInteger**)addr);
                break;
            case 'f':   // float
                number = [coder decodeObjectForKey:key];                
                f = [number floatValue];
                addr = (NSInteger)&f;
                object_setInstanceVariable(self, [key UTF8String], *(NSInteger**)addr);
                break;
            case 'd':   // double                
                number = [coder decodeObjectForKey:key];
                d = [number doubleValue];
                if ((ivar = class_getInstanceVariable([self class], [key UTF8String]))) {
                    varIndex = (double *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndex = d;
                }
                break;
            case 'i':   // int
                number = [coder decodeObjectForKey:key];
                i = [number intValue];
                addr = (NSInteger)&i;
                object_setInstanceVariable(self, [key UTF8String], *(NSInteger**)addr);
                break;
            case 'L':   // unsigned long
                number = [coder decodeObjectForKey:key];
                ul = [number unsignedLongValue];
                addr = (NSInteger)&ul;
                object_setInstanceVariable(self, [key UTF8String], *(NSInteger**)addr);
                break;
            case 'Q':   // unsigned long long
                number = [coder decodeObjectForKey:key];
                ull = [number unsignedLongLongValue];
                addr = (NSInteger)&ull;
                object_setInstanceVariable(self, [key UTF8String], *(NSInteger**)addr);
                break;
			case 'l':   // long
                number = [coder decodeObjectForKey:key];
                longValue = [number longValue];
                addr = (NSInteger)&longValue;
                object_setInstanceVariable(self, [key UTF8String], *(NSInteger**)addr);
                break;
            case 'I':   // unsigned
                number = [coder decodeObjectForKey:key];
                unsignedValue = [number unsignedIntValue];
                addr = (NSInteger)&unsignedValue;
                object_setInstanceVariable(self, [key UTF8String], *(NSInteger**)addr);
                break;
            case 's':   // short
                number = [coder decodeObjectForKey:key];
                shortValue = [number shortValue];
                addr = (NSInteger)&shortValue;
                object_setInstanceVariable(self, [key UTF8String], *(NSInteger**)addr);
                break;
				
            default:
                break;
        }
    }
}

@end