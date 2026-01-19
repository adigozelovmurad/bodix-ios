//
//  MainTabBarController.swift
//  Bodix
//
//  Created by MURAD on 4.01.2026.
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()

        

        
    }

    private func setupTabs() {
        let home = HomeViewController()
        let workout = WorkoutViewController()
        let steps = StepsViewController()
        let settings = SettingsViewController()

        settings.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )


        

        home.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)
        workout.tabBarItem = UITabBarItem(title: "Workout", image: UIImage(systemName: "dumbbell"), tag: 1)
        steps.tabBarItem = UITabBarItem(title: "Steps", image: UIImage(systemName: "figure.walk"), tag: 2)
        settings.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 3)

        viewControllers = [
            UINavigationController(rootViewController: home),
            UINavigationController(rootViewController: workout),
            UINavigationController(rootViewController: steps),
            UINavigationController(rootViewController: settings)
        ]
    }

    private func setupAppearance() {
        tabBar.tintColor = UIColor(named: "BrandPrimary")
        tabBar.unselectedItemTintColor = .systemGray
        tabBar.backgroundColor = .systemBackground

        
    }

}
