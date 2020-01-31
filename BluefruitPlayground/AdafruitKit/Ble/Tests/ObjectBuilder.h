//
//  ObjectBuilder.h
//  BluefruitPlayground
//
//  Created by Antonio García on 16/12/2019.
//  Copyright © 2019 Adafruit. All rights reserved.
//

// from: https://forums.developer.apple.com/thread/29851

#ifndef ObjectBuilder_h
#define ObjectBuilder_h

#import <Foundation/Foundation.h>

@interface ObjectBuilder: NSObject
+ (id)createInstanceOfClass:(NSString *)name;
@end

#endif /* ObjectBuilder_h */
