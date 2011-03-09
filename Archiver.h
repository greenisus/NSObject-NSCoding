//
//  Archiver.h
//  OpenStack
//
//  Created by Mike Mayo on 10/4/10.
//  The OpenStack project is provided under the Apache 2.0 license.
//

#import <Foundation/Foundation.h>


@interface Archiver : NSObject {

}

+ (id)retrieve:(NSString *)key;
+ (BOOL)persist:(id)object key:(NSString *)key;
+ (BOOL)delete:(NSString *)key;
+ (BOOL)deleteEverything;

@end
