//
//  HomeStatView.swift
//  Bodix
//
//  Created by MURAD on 5.01.2026.
//

import UIKit

final class HomeStatView: UIView {

    private let valueLabel = UILabel()
    private let titleLabel = UILabel()
    

    init(value: String, title: String) {
        super.init(frame: .zero)
        setupUI()
        configure(value: value, title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(value: String) {
        valueLabel.text = value
    }


    private func setupUI() {
        backgroundColor = .tertiarySystemBackground
        layer.cornerRadius = 12

        valueLabel.font = .systemFont(ofSize: 18, weight: .bold)
        valueLabel.textAlignment = .center

        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    private func configure(value: String, title: String) {
        valueLabel.text = value
        titleLabel.text = title

        // Accessibility
        isAccessibilityElement = true
        accessibilityLabel = "\(title): \(value)"
    }

    // Dəyəri dinamik yeniləmək üçün
    func updateValue(_ newValue: String) {
        valueLabel.text = newValue
        accessibilityLabel = "\(titleLabel.text ?? ""): \(newValue)"
    }
}
