//
//  NSImageView+SESContentModes.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 12/05/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//
import Cocoa
enum SESViewContentMode : Int {
    case scaleToFill
    case scaleAspectFit
    case scaleAspectFill
    case redraw
    case center
    case top
    case bottom
    case left
    case right
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

class SESImageView: NSImageView {
    var contentMode = SESViewContentMode(rawValue: 0)


    override init() {
        super.init()
        
        super.imageScaling = NSImageScaleAxesIndependently
    
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(aDecoder)
        
        super.imageScaling = NSImageScaleAxesIndependently
    
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        super.imageScaling = NSImageScaleAxesIndependently
    
    }

    func setImageScaling(_ newScaling: NSImageScaling) {
        // That's necessary to use nothing but NSImageScaleAxesIndependently
        super.imageScaling = NSImageScaleAxesIndependently
    }

    override func setImage(_ image: NSImage) {
        if image == nil {
            super.image = image
            return
        }
        var scaleToFillImage = NSImage(self.bounds.size, flipped: false, drawingHandler: {(_ dstRect: NSRect) -> BOOL in
                var imageSize = image.size
                var imageViewSize = self.bounds.size
                    // Yes, do not use dstRect.
                var newImageSize = imageSize
                var imageAspectRatio: CGFloat = imageSize.height / imageSize.width
                var imageViewAspectRatio: CGFloat = imageViewSize.height / imageViewSize.width
                if imageAspectRatio < imageViewAspectRatio {
                    // Image is more horizontal than the view. Image left and right borders need to be cropped.
                    newImageSize.width = imageSize.height / imageViewAspectRatio
                }
                else {
                    // Image is more vertical than the view. Image top and bottom borders need to be cropped.
                    newImageSize.height = imageSize.width * imageViewAspectRatio
                }
                var srcRect = NSMakeRect(imageSize.width / 2.0 - newImageSize.width / 2.0, imageSize.height / 2.0 - newImageSize.height / 2.0, newImageSize.width, newImageSize.height)
                NSGraphicsContext.current.imageInterpolation = NSImageInterpolationHigh
                image.draw(in: dstRect, from: srcRect, operation: NSCompositeCopy, fraction: 1.0, respectFlipped: true, hints: [NSImageHintInterpolation: (NSImageInterpolationHigh)])
                return true
            })
        scaleToFillImage.cacheMode = NSImageCacheNever
        // Hence it will automatically redraw with new frame size of the image view.
        super.image = scaleToFillImage
    }
}
//
//  NSImageView+SESContentModes.m
//  Transmote
//
//  Created by Sam Easterby-Smith on 12/05/2014.
//  Copyright (c) 2014 Spotlight Kid. All rights reserved.
//
import ObjectiveC