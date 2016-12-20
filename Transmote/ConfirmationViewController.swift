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
    
    @IBOutlet weak var messageField: NSTextField!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!

    var action: (()->())?
    var message: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let message = message {
            self.messageField.stringValue = message
        }
    }
    
    @IBAction func cancelButtonClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func deleteButtonClicked(_ sender: Any) {
        action?()
        self.dismiss(self)
    }
}
