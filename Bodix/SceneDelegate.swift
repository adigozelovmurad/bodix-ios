//
//  SceneDelegate.swift
//  Bodix
//
//  Created by MURAD on 15.12.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {



    var window: UIWindow?

    func sceneDidBecomeActive(_ scene: UIScene) {
        //   StepsManager.shared.prewarm()
        AppearanceManager.shared.applyAppearance()
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)

        let hasSeenOnboarding =
            UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

        if hasSeenOnboarding {
            window.rootViewController = MainTabBarController()
        } else {
            window.rootViewController = OnboardingContainerViewController()
        }

        window.makeKeyAndVisible()
        self.window = window

        AppearanceManager.shared.applyAppearance()
    }




}
