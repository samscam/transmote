////
////  NSImageView+SESContentModes.h
////  Transmote
////
////  Created by Sam Easterby-Smith on 12/05/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
import Foundation
import AppKit
import QuartzCore

import RxSwift
import RxCocoa

public enum ContentMode : Int {
    case scaleToFill
    case scaleAspectFit
    case scaleAspectFill
//    case redraw
    case center
//    case top
//    case bottom
//    case left
//    case right
//    case topLeft
//    case topRight
//    case bottomLeft
//    case bottomRight
}

public class ProperImageView: NSView {
    
    // Public properties
    public var image: NSImage? {
        set{
//            print("\(newValue)")
            self.innerImageView.image = newValue
            self.updateLayout()
//            self.setNeedsDisplay(self.bounds)
//            self.layoutSubtreeIfNeeded()
        }
        get {
            return self.innerImageView.image
        }

    }
    
    public var contentMode: ContentMode = .center {
        didSet{
            self.updateLayout()
        }
    }
    
    // Initialisation
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        sharedInit()
    }
    
    let innerImageView: NSImageView = NSImageView()
    
    func sharedInit(){
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        innerImageView.imageScaling = .scaleAxesIndependently
        self.addSubview(innerImageView)
        innerImageView.layer?.opacity = 0.3
        self.layer?.backgroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
//        self.innerImageView.layer?.backgroundColor =  CGColor(red: 0, green: 2, blue: 0, alpha: 1)
    }

    public func updateLayout() {
        
        guard let imageSize = self.image?.size  else {
            return
        }
        
        let bounds = self.bounds
        let imageAspect = imageSize.width / imageSize.height
        let boundsAspect = bounds.width / bounds.height
        let result: CGRect
        
        switch self.contentMode {
        case .scaleAspectFill:
            if (imageAspect > boundsAspect ) {
                result = CGRect(x: ( -((imageAspect * bounds.height) - bounds.width) / 2 )  , y: 0, width: imageAspect * bounds.height, height: bounds.height)
            } else {
                result = CGRect(x: 0 , y:  -( ( bounds.width / imageAspect) - bounds.height) / 2, width: bounds.width, height:  bounds.width / imageAspect)
            }
        case .scaleAspectFit:
            result = bounds
        case .scaleToFill:
            result = bounds
            
//        case .bottom:
//        case .bottomLeft:
//        case .bottomRight:
        case .center:
            result = CGRect(x: (bounds.width - imageSize.width)/2, y: (bounds.height - imageSize.height)/2, width: imageSize.width, height: imageSize.height)
//        case .left:
//        case .redraw:
//        case .right:
//        case .top:
//        case .topLeft:
//        case .topRight:
            
        }
        
        self.innerImageView.frame = result
    }
    
    override public func layout() {
        super.layout()
        self.updateLayout()
    }
    
}


extension Reactive where Base: ProperImageView {
    
    /// Bindable sink for `image` property.
    public var image: UIBindingObserver<Base, NSImage?> {
        return UIBindingObserver(UIElement: self.base) { control, value in
            control.image = value
        }
    }
}

//    var contentMode = SESViewContentMode(rawValue: 0)
//
//
//    override init() {
//        super.init()
//        
//        super.imageScaling = NSImageScaleAxesIndependently
//    
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(aDecoder)
//        
//        super.imageScaling = NSImageScaleAxesIndependently
//    
//    }
//
//    override init(frame frameRect: NSRect) {
//        super.init(frame: frameRect)
//        
//        super.imageScaling = NSImageScaleAxesIndependently
//    
//    }
//
//    func setImageScaling(_ newScaling: NSImageScaling) {
//        // That's necessary to use nothing but NSImageScaleAxesIndependently
//        super.imageScaling = NSImageScaleAxesIndependently
//    }
//
//    override func setImage(_ image: NSImage) {
//        if image == nil {
//            super.image = image
//            return
//        }
//        var scaleToFillImage = NSImage(self.bounds.size, flipped: false, drawingHandler: {(_ dstRect: NSRect) -> BOOL in
//                var imageSize = image.size
//                var imageViewSize = self.bounds.size
//                    // Yes, do not use dstRect.
//                var newImageSize = imageSize
//                var imageAspectRatio: CGFloat = imageSize.height / imageSize.width
//                var imageViewAspectRatio: CGFloat = imageViewSize.height / imageViewSize.width
//                if imageAspectRatio < imageViewAspectRatio {
//                    // Image is more horizontal than the view. Image left and right borders need to be cropped.
//                    newImageSize.width = imageSize.height / imageViewAspectRatio
//                }
//                else {
//                    // Image is more vertical than the view. Image top and bottom borders need to be cropped.
//                    newImageSize.height = imageSize.width * imageViewAspectRatio
//                }
//                var srcRect = NSMakeRect(imageSize.width / 2.0 - newImageSize.width / 2.0, imageSize.height / 2.0 - newImageSize.height / 2.0, newImageSize.width, newImageSize.height)
//                NSGraphicsContext.current.imageInterpolation = NSImageInterpolationHigh
//                image.draw(in: dstRect, from: srcRect, operation: NSCompositeCopy, fraction: 1.0, respectFlipped: true, hints: [NSImageHintInterpolation: (NSImageInterpolationHigh)])
//                return true
//            })
//        scaleToFillImage.cacheMode = NSImageCacheNever
//        // Hence it will automatically redraw with new frame size of the image view.
//        super.image = scaleToFillImage
//    }
//}
////
////  NSImageView+SESContentModes.m
////  Transmote
////
////  Created by Sam Easterby-Smith on 12/05/2014.
////  Copyright (c) 2014 Spotlight Kid. All rights reserved.
////
//import ObjectiveC
