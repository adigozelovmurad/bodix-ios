//
//  MotionPermissionViewController.swift
//  Bodix
//
//  Created by MURAD on 18.01.2026.
//

import UIKit

final class OnboardingIntro1ViewController: UIViewController {

    var onContinue: (() -> Void)?

    private let iconView = UIImageView(image: UIImage(systemName: "figure.walk"))
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let continueButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        iconView.tintColor = UIColor(named: "BrandPrimary") ?? .systemBlue
        iconView.contentMode = .scaleAspectFit

        titleLabel.text = "Track Your Steps"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center

        descriptionLabel.text = """
Track your daily steps and activity with Bodix.
"""
        descriptionLabel.font = .systemFont(ofSize: 16)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

        continueButton.setTitle("Continue", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        continueButton.backgroundColor = UIColor(named: "BrandPrimary") ?? .systemBlue
        continueButton.tintColor = .white
        continueButton.layer.cornerRadius = 14
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)

        [iconView, titleLabel, descriptionLabel, continueButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.heightAnchor.constraint(equalToConstant: 80),
            iconView.widthAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    @objc private func continueTapped() {
        onContinue?()
    }
}
