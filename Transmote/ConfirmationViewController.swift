//
//  ConfirmationViewController.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 19/12/2016.
//  Copyright © 2016 Sam Easterby-Smith. All rights reserved.
//

import Foundation
import AppKit

class ConfirmationViewController: NSViewController {
    var session: TransmissionSession?
    
    @IBOutlet weak var messageField: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!

    @IBAction func cancelButtonClicked(_ sender: Any) {
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
    }
}
