//
//  ListLayout.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 16/02/2017.
//

import Foundation
import AppKit

/// This has one column of cells
class ListLayout: NSCollectionViewLayout {

    let itemHeight: Double = 70.0
    var width: Double = 0.0

    var numberOfItems = 0
    var itemHeights: [IndexPath:CGFloat] = [:]

    override func prepare() {
        guard let collectionView = self.collectionView, let superview = collectionView.superview else {
            return
        }
        numberOfItems = collectionView.numberOfItems(inSection: 0)
        width = Double(superview.bounds.size.width)
    }

    override var collectionViewContentSize: NSSize {
        return NSSize(width: width, height: 10.0 + ((itemHeight + 5.0) * Double(numberOfItems) ))
    }

    override func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        var attribs: [NSCollectionViewLayoutAttributes] = []
        for i in 0 ..< numberOfItems {
            attribs.append(layoutAttributesForItem(at: IndexPath(item: i, section: 0))!)
        }
        return attribs
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {

        let attribs = NSCollectionViewLayoutAttributes(forItemWith: indexPath)

        let rect = NSRect(x: 0.0, y: (5.0 + ((itemHeight + 5.0) * Double(indexPath.item))), width: width, height: itemHeight)
        attribs.frame = rect.insetBy(dx: 5, dy: 0)
        return attribs
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
        return true
    }
}
