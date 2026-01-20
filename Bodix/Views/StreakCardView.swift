//
//  StreakCardView.swift
//  Bodix
//
//  Created by MURAD on 20.01.2026.
//

import UIKit

final class StreakCardView: UIView {

     let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 14

        iconView.image = UIImage(systemName: "flame.fill")
        iconView.tintColor = .systemOrange

        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .label

        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [iconView, textStack])
        mainStack.axis = .horizontal
        mainStack.spacing = 12
        mainStack.alignment = .center

        addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    func update(streak: Int, goalReachedToday: Bool) {
        if streak > 0 {
            titleLabel.text = "🔥 \(streak) Day Streak"
            subtitleLabel.text = goalReachedToday
                ? "You’ve hit your goal today!"
                : "Keep going to extend your streak"
        } else {
            titleLabel.text = "No streak yet"
            subtitleLabel.text = "Reach today’s goal to start!"
        }
    }

    func playGoalReachedAnimation() {
        // Scale animation
        UIView.animate(withDuration: 0.15, animations: {
            self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                self.transform = .identity
            }
        }

        // Flame pulse
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 0.6,
                       options: []) {
            self.iconView.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.iconView.transform = .identity
            }
        }
    }

}
