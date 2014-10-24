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
                    value = [self performSelector:NSSelectorFromString(key)];
					
                    // only decode if the property conforms to NSCoding
                    if([class conformsToProtocol:@protocol(NSCoding)]){
                        [coder encodeObject:value forKey:key];
                    }
                }
                break;
            case 'B':
                [invocation invoke];
                [invocation getReturnValue:&boolValue];
                [coder encodeObject:[NSNumber numberWithBool:boolValue] forKey:key];
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
                [coder encodeObject:[NSNumber numberWithInteger:intValue] forKey:key];
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

- (void)autoDecode:(NSCoder *)coder {
    NSDictionary *properties = [self properties];
    for (NSString *key in properties) {
        NSString *ivarKey = [@"_"stringByAppendingString:key];
        NSString *type = [properties objectForKey:key];
        NSNumber *number;
        unsigned int addr;
        NSInteger i;
        CGFloat f;
        BOOL b;
        double d;
        unsigned long ul;
        unsigned long long ull;
		long longValue;
        long long longLongValue;
		unsigned unsignedValue;
		short shortValue;
        Ivar ivar;
        
        bool *varIndexBool;
        float *varIndexFloat;
        double *varIndexDouble;
        unsigned long long *varIndexULongLong;
        unsigned long *varIndexULong;
        long *varIndexLong;
        long long *varIndexLongLong;
        unsigned *varU;
        short *varShort;
        
        NSString *className;
        switch ([type characterAtIndex:0]) {
            case '@':   // object
                if ([[type componentsSeparatedByString:@"\""] count] > 1) {
                    className = [[type componentsSeparatedByString:@"\""] objectAtIndex:1];                    
                    Class class = NSClassFromString(className);
                    // only decode if the property conforms to NSCoding
                    if ([class conformsToProtocol:@protocol(NSCoding )]){
                        id value = [coder decodeObjectForKey:key];
//                        object_setInstanceVariable(self, [ivarKey UTF8String], &value);
                        [self setValue:value forKey:key];
                    }
                }
                break;
            case 'B':   // bool
                number = [coder decodeObjectForKey:key];
                b = [number boolValue];
                
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexBool = (bool *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexBool = b;
                }
                break;
            case 'c':   // bool
                number = [coder decodeObjectForKey:key];                
                b = [number boolValue];
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexBool = (bool *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexBool = b;
                }
                break;
            case 'f':   // float
                number = [coder decodeObjectForKey:key];                
                f = [number floatValue];
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexFloat = (float *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexFloat = f;
                }
                break;
            case 'd':   // double                
                number = [coder decodeObjectForKey:key];
                d = [number doubleValue];
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexDouble = (double *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexDouble = d;
                }
                break;
            case 'i':   // int
                number = [coder decodeObjectForKey:key];
                i = [number intValue];
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexLong = (long *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexLong = i;
                }
                break;
            case 'L':   // unsigned long
                number = [coder decodeObjectForKey:key];
                ul = [number unsignedLongValue];

                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexULong = (unsigned long *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexULong = ul;
                }
                
                break;
            case 'Q':   // unsigned long long
                number = [coder decodeObjectForKey:key];
                ull = [number unsignedLongLongValue];
                addr = (unsigned int)&ull;
                
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexULongLong = (unsigned long long *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexULongLong = ull;
                }
                break;
			case 'l':   // long
                number = [coder decodeObjectForKey:key];
                longValue = [number longValue];
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexLong = (long *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexLong = longValue;
                }
                break;
            case 'I':   // unsigned
                number = [coder decodeObjectForKey:key];
                unsignedValue = [number unsignedIntValue];
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varU = (unsigned *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varU = unsignedValue;
                }
                break;
            case 's':   // short
                number = [coder decodeObjectForKey:key];
                shortValue = [number shortValue];
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varShort = (short *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varShort = shortValue;
                }
                break;
            case 'q':   // long long
                number = [coder decodeObjectForKey:key];
                longLongValue = [number longLongValue];
                if ((ivar = class_getInstanceVariable([self class], [ivarKey UTF8String]))) {
                    varIndexLongLong = (long long *)(void **)((char *)self + ivar_getOffset(ivar));
                    *varIndexLongLong = longLongValue;
                }
                break;
				
            default:
                break;
        }
    }
}

@end
