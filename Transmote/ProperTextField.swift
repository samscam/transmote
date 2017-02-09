//
//  ProperNSTextField.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 07/02/2017.
//

import Foundation
import AppKit

protocol ProperTextFieldDelegate: class {
    func textFieldDidBecomeFirstResponder(_ sender: NSTextField)
    func textFieldDidResignFirstResponder(_ sender: NSTextField)
}

class ProperTextField: NSTextField {

    weak var pdelegate: ProperTextFieldDelegate?

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        pdelegate?.textFieldDidBecomeFirstResponder(self)
        return true
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        pdelegate?.textFieldDidResignFirstResponder(self)
        return true
    }
}

class ProperSecureTextField: NSSecureTextField {

    weak var pdelegate: ProperTextFieldDelegate?

    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        pdelegate?.textFieldDidBecomeFirstResponder(self)
        return true
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        pdelegate?.textFieldDidResignFirstResponder(self)
        return true
    }
}
