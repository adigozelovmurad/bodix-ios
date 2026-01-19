//
//   HapticManager.swift
//  Bodix
//
//  Created by MURAD on 18.01.2026.
//

import UIKit

final class HapticManager {

    static let shared = HapticManager()
    private init() {}

    private let key = "haptics_enabled"

    var isEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: key) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

extension HapticManager {

    func toggle() {
        selection()
    }

    func action() {
        impact(.medium)
    }

    func success() {
        notification(.success)
    }
}
