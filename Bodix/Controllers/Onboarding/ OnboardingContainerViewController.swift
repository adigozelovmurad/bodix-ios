//
//  OnboardingPermissionViewController.swift
//  Bodix
//
//  Created by MURAD on 18.01.2026.
//

import UIKit

final class OnboardingContainerViewController: UIViewController {

    private let intro1 = OnboardingIntro1ViewController()
    private let intro2 = OnboardingIntro2ViewController()
    private let pageControl = UIPageControl()


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupPageControl()
        showIntro1()
        addSwipeGesture()

    }

    private func addSwipeGesture() {
        let swipeRight = UISwipeGestureRecognizer(
            target: self,
            action: #selector(handleSwipeBack)
        )
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }


    private func showIntro1() {
        pageControl.currentPage = 0

        intro1.onContinue = { [weak self] in
            self?.showIntro2()
        }

        // 🔥 ƏVVƏLKİ CHILD-I TƏMİZLƏ
        if let current = children.first {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        set(child: intro1)
    }


    private func showIntro2() {
        pageControl.currentPage = 1

        intro2.onFinish = { [weak self] in
            self?.finishOnboarding()
        }
        transition(to: intro2)
    }


    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")

        let tabBar = MainTabBarController()

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController = tabBar
            window.makeKeyAndVisible()
        }
    }

    private func setupPageControl() {
        pageControl.numberOfPages = 2
        pageControl.currentPage = 0
        pageControl.isUserInteractionEnabled = false // ❗ swipe olmasın
        pageControl.currentPageIndicatorTintColor =
            UIColor(named: "BrandPrimary") ?? .systemBlue
        pageControl.pageIndicatorTintColor = .systemGray4

        view.addSubview(pageControl)
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -96
            ),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }


    // MARK: - Child handling

    private func set(child: UIViewController) {
        addChild(child)
        child.view.frame = view.bounds
        view.addSubview(child.view)

        // 🔥 ƏN VACİB SƏTİR
        view.bringSubviewToFront(pageControl)

        child.didMove(toParent: self)
    }


    private func transition(to new: UIViewController) {
        guard let current = children.first else {
            set(child: new)
            return
        }

        current.willMove(toParent: nil)
        addChild(new)
        new.view.frame = view.bounds

        transition(
            from: current,
            to: new,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil
        ) { _ in
            current.removeFromParent()
            new.didMove(toParent: self)

            // 🔥 BURADA DA
            self.view.bringSubviewToFront(self.pageControl)
        }
    }
    @objc private func handleSwipeBack() {
        guard pageControl.currentPage == 1 else { return }
        showIntro1()
    }


}
