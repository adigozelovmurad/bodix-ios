//
//  StatsCardView.swift
//  Bodix
//
//  Created by MURAD on 8.01.2026.
//

import UIKit

final class StatsCardView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = .systemBlue
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()

    private let valueLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textAlignment = .center
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()

    private let unitLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        return l
    }()

    // MARK: - Init
    init(icon: String, title: String, value: String, unit: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: icon)
        titleLabel.text = title
        valueLabel.text = value
        unitLabel.text = unit
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16

        let stack = UIStackView(arrangedSubviews: [
            iconView,
            titleLabel,
            valueLabel,
            unitLabel
        ])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    // MARK: - Update
    func updateValue(_ newValue: String) {
        UIView.transition(
            with: valueLabel,
            duration: 0.25,
            options: .transitionCrossDissolve
        ) {
            self.valueLabel.text = newValue
        }
    }
}
