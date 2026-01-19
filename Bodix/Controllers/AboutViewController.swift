//
//  AboutViewController.swift
//  Bodix
//
//  Created by MURAD on 17.01.2026.
//

import UIKit

final class AboutViewController: UIViewController {

    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "About"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center

        let appName = UILabel()
        appName.text = "Bodix"
        appName.font = .systemFont(ofSize: 28, weight: .bold)

        let version = UILabel()
        version.font = .systemFont(ofSize: 14)
        version.textColor = .secondaryLabel
        version.text = appVersionText()

        let description = UILabel()
        description.font = .systemFont(ofSize: 15)
        description.textColor = .secondaryLabel
        description.numberOfLines = 0
        description.textAlignment = .center
        description.text = """
Bodix helps you track your daily steps and stay consistent with your fitness goals.

All health data is processed locally on your device.
"""

        let copyright = UILabel()
        copyright.font = .systemFont(ofSize: 13)
        copyright.textColor = .tertiaryLabel
        copyright.text = "© 2026 Bodix"

        [appName, version, description, copyright].forEach {
            stack.addArrangedSubview($0)
        }

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func appVersionText() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}
