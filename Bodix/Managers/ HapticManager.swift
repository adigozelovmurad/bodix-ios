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

    // MARK: - Toggle
    var isEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: key) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }

    // MARK: - Base generators

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let gen = UIImpactFeedbackGenerator(style: style)
        gen.prepare()
        gen.impactOccurred()
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let gen = UINotificationFeedbackGenerator()
        gen.prepare()
        gen.notificationOccurred(type)
    }

    func selection() {
        guard isEnabled else { return }
        let gen = UISelectionFeedbackGenerator()
        gen.prepare()
        gen.selectionChanged()
    }
}

// MARK: - Semantic helpers (UI üçün rahat istifadə)

extension HapticManager {

    /// Switch, toggle, seçimlər üçün
    func toggle() {
        selection()
    }

    /// Button, action tap üçün
    func action() {
        impact(.medium)
    }

    /// Uğur qazandıqda (goal, streak, save və s.)
    func success() {
        notification(.success)
    }

    /// Xəta baş verəndə
    func error() {
        notification(.error)
    }

    /// Warning / limit
    func warning() {
        notification(.warning)
    }

    /// Kiçik feedback (chart tap, mini interaction)
    func light() {
        impact(.light)
    }

    /// Güclü feedback (delete, reset və s.)
    func heavy() {
        impact(.heavy)
    }
}
