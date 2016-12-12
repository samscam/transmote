//
//  Backoff.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 12/12/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation

class BackoffTimer {
    let min: TimeInterval
    let max: TimeInterval
    let block: ()->()
    let steps: Int = 10
    var count: Int = 0
    var timer: Timer?
    
    init?(min: TimeInterval, max: TimeInterval, block:@escaping ()->()){
        guard min <= max else {
            return nil
        }
        self.min = min
        self.max = max
        self.block = block
        fire()
    }
    
    func fire(){

        let time: TimeInterval = min + ((max - min) / Double(steps)) * Double(count)
        timer = Timer.scheduledTimer(withTimeInterval: time, repeats: false, block: { (timer) in
            self.block()
            self.fire()
        })
        count += 1
    }
    
    func invalidate(){
        timer?.invalidate()
    }
    
    deinit {
        invalidate()
    }
}
