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

- (NSMutableDictionary *) propertiesForClass:(Class)klass
{
    
    NSMutableDictionary *results = [NSMutableDictionary new];
    
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(klass, &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];

        NSString *pname = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSString *pattrs = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        
        NSArray *comps = [pattrs componentsSeparatedByString:@","];
        pattrs = [comps objectAtIndex:0];
        pattrs = [pattrs substringFromIndex:1];

        [results setObject:pattrs forKey:pname];
    }
    free(properties);
    
    if ([klass superclass] != [NSObject class]) {
        [results addEntriesFromDictionary:[self propertiesForClass:[klass superclass]]];
    }
    
    return results;
}

- (NSDictionary *) properties
{
    return [self propertiesForClass:[self class]];
}

- (void) autoEncodeWithCoder:(NSCoder *)coder
{
    NSDictionary *properties = [self properties];

    for (NSString *key in properties)
    {
        NSString *type = [properties objectForKey:key];
        id value;
        unsigned long long ullValue;
        long long llValue;
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    value = [self performSelector:NSSelectorFromString(key)];
#pragma clang diagnostic pop
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
            case 'q':   // long long
                [invocation invoke];
                [invocation getReturnValue:&llValue];
                [coder encodeObject:[NSNumber numberWithLongLong:llValue] forKey:key];
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

- (void) autoDecode:(NSCoder *)coder
{
    NSDictionary *properties = [self properties];

    for (NSString *key in properties)
    {
        NSString *capitalizedKey = [key stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[key substringToIndex:1] capitalizedString]];
        NSString *selectorString = [NSString stringWithFormat:@"set%@:", capitalizedKey];
        SEL selector = NSSelectorFromString(selectorString);
        NSMethodSignature *signature = [self methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setSelector:selector];
        [invocation setTarget:self];

        NSString *type = [properties objectForKey:key];
        id value;
        NSNumber *number;
        NSInteger i;
        CGFloat f;
        BOOL b;
        double d;
        unsigned long ul;
        unsigned long long ull;
        long long ll;
		long longValue;
		unsigned unsignedValue;
		short shortValue;

        switch ([type characterAtIndex:0])
        {
            case '@': // object
                if ([[type componentsSeparatedByString:@"\""] count] > 1)
                {
                    NSString *className = [[type componentsSeparatedByString:@"\""] objectAtIndex:1];
                    Class class = NSClassFromString(className);
                    // only decode if the property conforms to NSCoding
                    if ([class conformsToProtocol:@protocol(NSCoding)]){
                        @try {
                            value = [coder decodeObjectForKey:key];
                        }
                        @catch (NSException *exception) {
                            NSLog(@"Warning: %@", exception);
                            continue;
                        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [self performSelector:selector withObject:value];
#pragma clang diagnostic pop
                    }
                }
                break;
            case 'c':   // bool
                number = [coder decodeObjectForKey:key];
                b = [number boolValue];
                [invocation setArgument:&b atIndex:2];
                [invocation invoke];
                break;
            case 'f':   // float
                number = [coder decodeObjectForKey:key];
                f = [number floatValue];
                [invocation setArgument:&f atIndex:2];
                [invocation invoke];
                break;
            case 'd':   // double
                number = [coder decodeObjectForKey:key];
                d = [number doubleValue];
                [invocation setArgument:&d atIndex:2];
                [invocation invoke];
                break;
            case 'i':   // int
                number = [coder decodeObjectForKey:key];
                i = [number intValue];
                [invocation setArgument:&i atIndex:2];
                [invocation invoke];
                break;
            case 'L':   // unsigned long
                number = [coder decodeObjectForKey:key];
                ul = [number unsignedLongValue];
                [invocation setArgument:&ul atIndex:2];
                [invocation invoke];
                break;
            case 'q':   // long long
                number = [coder decodeObjectForKey:key];
                ll = [number longLongValue];
                [invocation setArgument:&ll atIndex:2];
                [invocation invoke];
                break;
            case 'Q':   // unsigned long long
                number = [coder decodeObjectForKey:key];
                ull = [number unsignedLongLongValue];
                [invocation setArgument:&ull atIndex:2];
                [invocation invoke];
                break;
			case 'l':   // long
                number = [coder decodeObjectForKey:key];
                longValue = [number longValue];
                [invocation setArgument:&longValue atIndex:2];
                [invocation invoke];
                break;
            case 'I':   // unsigned
                number = [coder decodeObjectForKey:key];
                unsignedValue = [number unsignedIntValue];
                [invocation setArgument:&unsignedValue atIndex:2];
                [invocation invoke];
                break;
            case 's':   // short
                number = [coder decodeObjectForKey:key];
                shortValue = [number shortValue];
                [invocation setArgument:&shortValue atIndex:2];
                [invocation invoke];
                break;
				
            default:
                break;
        }
    }
}

@end