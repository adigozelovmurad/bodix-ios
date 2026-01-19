//
//  StepsPermissionView.swift
//  Bodix
//
//  Created by MURAD on 18.01.2026.
//

import UIKit

final class StepsPermissionView: UIView {

    let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setup() {
        backgroundColor = .systemBackground

        let icon = UIImageView(image: UIImage(systemName: "figure.walk"))
        icon.tintColor = .systemBlue
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "Allow Step Tracking"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        let desc = UILabel()
        desc.text = """
Bodix needs motion access to show your steps.

Your data stays on your device.
"""
        desc.font = .systemFont(ofSize: 15)
        desc.textColor = .secondaryLabel
        desc.textAlignment = .center
        desc.numberOfLines = 0
        desc.translatesAutoresizingMaskIntoConstraints = false

        button.setTitle("Allow Access", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [icon, title, desc, button])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            icon.heightAnchor.constraint(equalToConstant: 60),
            icon.widthAnchor.constraint(equalToConstant: 60),

            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
    }
}

