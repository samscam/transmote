//
//  SettingsViewController.swift
//  Transmote
//
//  Created by Sam Easterby-Smith on 22/11/2016.
//

import Foundation
import Cocoa

import RxSwift
import RxCocoa

protocol SettingsPopoverDelegate: class {
    func settingsDismissed(sender: SettingsViewController)
}

class SettingsViewController: NSViewController, ProperTextFieldDelegate {

    var session: TransmissionSession?
    var viewModel: SettingsViewModel!

    weak var delegate: SettingsPopoverDelegate?

    @IBOutlet weak private var statusBlobImageView: NSImageView!

    @IBOutlet weak private var serverAddressField: NSTextField!

    @IBOutlet weak private var portField: NSTextField!
    @IBOutlet weak private var rpcPathField: NSTextField!
    @IBOutlet weak private var usernameField: NSTextField!
    @IBOutlet weak private var passwordField: ProperSecureTextField!

    @IBOutlet weak private var rpcPathStack: NSStackView!
    @IBOutlet weak private var usernameStack: NSStackView!
    @IBOutlet weak private var passwordStack: NSStackView!

    var disposeBag: DisposeBag = DisposeBag()
    var showingFakePassword: Bool = false

    var showAuthThings: Bool = true {
        didSet {
            usernameStack.isHidden = !showAuthThings
            passwordStack.isHidden = !showAuthThings
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let session = session else {
            return
        }

        viewModel = SettingsViewModel(session: session)
        bindViewModel()

        passwordField.pdelegate = self

    }

    func bindViewModel() {
        // Observe the session status
        viewModel.statusBlobImage.drive(statusBlobImageView.rx.image).addDisposableTo(disposeBag)
        serverAddressField.rx.text <-> viewModel.serverHost
        portField.rx.text <-> viewModel.serverPort
        rpcPathField.rx.text <-> viewModel.serverPath
        usernameField.rx.text <-> viewModel.serverUsername
        passwordField.rx.text <-> viewModel.serverPassword
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.delegate?.settingsDismissed(sender: self)
    }

    internal func textFieldDidBecomeFirstResponder(_ sender: NSTextField) {
        if showingFakePassword {
            sender.stringValue = ""
            showingFakePassword = false
        }
    }

    internal func textFieldDidResignFirstResponder(_ sender: NSTextField) {
        // do nothing
    }

}

infix operator <->

@discardableResult
func <-> <T>(property: ControlProperty<T>, variable: Variable<T>) -> Disposable {
    let variableToProperty = variable.asObservable()
        .bindTo(property)

    let propertyToVariable = property
        .subscribe(
            onNext: { variable.value = $0 },
            onCompleted: { variableToProperty.dispose() }
    )

    return Disposables.create(variableToProperty, propertyToVariable)
}
