//
//  ObjectBuilder.m
//  BluefruitPlayground
//
//  Created by Antonio García on 16/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//


#import "ObjectBuilder.h"

@implementation ObjectBuilder
+ (id)createInstanceOfClass:(NSString *)name {
  
    return [[NSClassFromString(name) alloc] init];
}
@end
