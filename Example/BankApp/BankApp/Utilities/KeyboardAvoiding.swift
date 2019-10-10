//
//  KeyboardAvoiding.swift
//
//  Created by Chris Ballinger on 7/24/19.
//

import UIKit

/// Helper class for auto-removing NotificationCenter observer tokens
final class ObservationToken {
    private let token: NSObjectProtocol

    deinit {
        NotificationCenter.default.removeObserver(token)
    }

    init(token: NSObjectProtocol) {
        self.token = token
    }
}

protocol KeyboardAvoiding where Self: UIViewController {
    typealias AnimationBlock = () -> Void
    typealias CompletionBlock = (Bool) -> Void
    /// Hold a strong reference to ObservationToken while you want to avoid the keyboard.
    func startAvoidingKeyboard(additionalAnimations: AnimationBlock?,
                               completion: CompletionBlock?) -> ObservationToken
}

extension KeyboardAvoiding {
    func startAvoidingKeyboard(additionalAnimations: AnimationBlock? = nil,
                               completion: CompletionBlock? = nil) -> ObservationToken {
        let observation = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main, using: { [weak self] (notification) in
            self?.onKeyboardFrameWillChangeNotificationReceived(notification, additionalAnimations: additionalAnimations)
        })
        return ObservationToken(token: observation)
    }

    private func onKeyboardFrameWillChangeNotificationReceived(_ notification: Notification, additionalAnimations: AnimationBlock? = nil, completion: CompletionBlock? = nil) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else {
                return
        }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let safeAreaFrame = view.safeAreaLayoutGuide.layoutFrame.insetBy(dx: 0, dy: -additionalSafeAreaInsets.bottom)
        let intersection = safeAreaFrame.intersection(keyboardFrameInView)

        let keyboardAnimationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
        let animationDuration: TimeInterval = (keyboardAnimationDuration as? NSNumber)?.doubleValue ?? 0
        let animationCurveRawNSN = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
        let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
        let animationCurve = UIView.AnimationOptions(rawValue: animationCurveRaw)

        UIView.animate(withDuration: animationDuration,
                       delay: 0,
                       options: [animationCurve, .allowUserInteraction],
                       animations: {
                        self.additionalSafeAreaInsets.bottom = intersection.height
                        additionalAnimations?()
                        self.view.layoutIfNeeded()
        }, completion: completion)
    }
}
