//
//  NSImageView+SESContentModes.h
//  Transmote
//
//  Created by Sam Easterby-Smith on 12/05/2014.
//

import Foundation
import AppKit
import QuartzCore

import RxSwift
import RxCocoa

public enum ContentMode: Int {
    case scaleToFill
    case scaleAspectFit
    case scaleAspectFill
    case center
/* 
     TODO: There are other modes in UIImageView which could be implemented:
    case redraw
    case top
    case bottom
    case left
    case right
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
 */
}

public class ProperImageView: NSView {

    // Public properties
    public var image: NSImage? {
        set {
            self.innerImageView.image = newValue
            self.updateLayout()
        }
        get {
            return self.innerImageView.image
        }

    }

    public var contentMode: ContentMode = .center {
        didSet {
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

    func sharedInit() {
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        innerImageView.imageScaling = .scaleAxesIndependently
        self.addSubview(innerImageView)
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
            if imageAspect > boundsAspect {
                result = CGRect(x: ( -((imageAspect * bounds.height) - bounds.width) / 2 ), y: 0, width: imageAspect * bounds.height, height: bounds.height)
            } else {
                result = CGRect(x: 0, y:  -( ( bounds.width / imageAspect) - bounds.height) / 2, width: bounds.width, height:  bounds.width / imageAspect)
            }
        case .scaleAspectFit:
            // erm yeah...
            result = bounds
        case .scaleToFill:
            result = bounds
        case .center:
            result = CGRect(x: (bounds.width - imageSize.width) / 2, y: (bounds.height - imageSize.height) / 2, width: imageSize.width, height: imageSize.height)

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

    public var contentMode: UIBindingObserver<Base, ContentMode> {
        return UIBindingObserver(UIElement: self.base) { control, value in
            control.contentMode = value
        }
    }
}
