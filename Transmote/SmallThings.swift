//
//  SmallThings.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 12/12/2016.
//

import Foundation

class BackoffTimer {
    let min: TimeInterval
    let max: TimeInterval
    let block: () -> Void
    let steps: Int = 10
    var count: Int = 0
    var timer: Timer?

    init?(min: TimeInterval, max: TimeInterval, block:@escaping () -> Void) {
        guard min <= max else {
            return nil
        }
        self.min = min
        self.max = max
        self.block = block
        fire()
    }

    func fire() {

        let time: TimeInterval = min + ((max - min) / Double(steps)) * Double(count)
        timer = Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { _ in
            self.block()
            self.fire()
        })
        count += 1
    }

    func invalidate() {
        timer?.invalidate()
    }

    deinit {
        invalidate()
    }
}

extension Collection where Iterator.Element: Hashable {
    func element(matching hash: Int) -> Iterator.Element? {
        return self.first(where: { $0.hashValue == hash })
    }
}
