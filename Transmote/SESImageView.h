//
//  NSImageView+SESContentModes.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 12/05/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum {
    SESViewContentModeScaleToFill,
    SESViewContentModeScaleAspectFit,
    SESViewContentModeScaleAspectFill,
    SESViewContentModeRedraw,
    SESViewContentModeCenter,
    SESViewContentModeTop,
    SESViewContentModeBottom,
    SESViewContentModeLeft,
    SESViewContentModeRight,
    SESViewContentModeTopLeft,
    SESViewContentModeTopRight,
    SESViewContentModeBottomLeft,
    SESViewContentModeBottomRight,
} SESViewContentMode;


@interface SESImageView:NSImageView

@property (nonatomic) SESViewContentMode contentMode;

@end
