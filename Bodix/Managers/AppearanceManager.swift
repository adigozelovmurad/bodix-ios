//
//  AppearanceManager.swift
//  Bodix
//
//  Created by MURAD on 16.01.2026.
//

import UIKit

enum AppAppearance: String {
    case system
    case dark
}

final class AppearanceManager {

    static let shared = AppearanceManager()
    private init() {}

    private let key = "app_appearance"

    var appearance: AppAppearance {
        get {
            let raw = UserDefaults.standard.string(forKey: key)
            return AppAppearance(rawValue: raw ?? "") ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            applyAppearance()
        }
    }

    func applyAppearance() {
        let style: UIUserInterfaceStyle
        
        switch appearance {
        case .system:
            style = .unspecified
        case .dark:
            style = .dark
        }

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}
