//
//  MouseWheel.m
//  GSRemote
//
//  Created by Niophys on 6/10/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

#import "MouseWheel.h"

@implementation MouseWheel

+ (void)scrollX:(int32_t) x andY: (int32_t) y {
    CGEventPost(kCGHIDEventTap, CGEventCreateScrollWheelEvent(NULL, kCGScrollEventUnitPixel, 2, y, x));
}

@end
