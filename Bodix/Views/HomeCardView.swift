//
//  HomeCardView.swift
//  Bodix
//
//  Created by MURAD on 5.01.2026.
//

import UIKit

enum HomeCardType {
    case steps
    case normal
}

final class HomeCardView: UIControl {

    private let cardType: HomeCardType

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let valueLabel = UILabel()
    private let progressView = CircularProgressView()
    private let miniChartView = HomeMiniChartView()

    // MARK: - Init
    init(
        title: String,
        subtitle: String,
        icon: String,
        type: HomeCardType = .normal
    ) {
        self.cardType = type
        super.init(frame: .zero)
        setupUI()
        configure(title: title, subtitle: subtitle, icon: icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16

        addTarget(self, action: #selector(touchDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchDragExit, .touchCancel])

        iconView.tintColor = .label
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        valueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        valueLabel.textAlignment = .right

        miniChartView.isHidden = cardType != .steps

        [iconView, titleLabel, subtitleLabel, valueLabel, progressView, miniChartView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: iconView.topAnchor),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            progressView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            progressView.centerYAnchor.constraint(equalTo: centerYAnchor),
            progressView.widthAnchor.constraint(equalToConstant: 30),
            progressView.heightAnchor.constraint(equalToConstant: 30),

            valueLabel.trailingAnchor.constraint(equalTo: progressView.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            miniChartView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            miniChartView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 8),
            miniChartView.trailingAnchor.constraint(equalTo: valueLabel.leadingAnchor, constant: -12),
            miniChartView.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func configure(title: String, subtitle: String, icon: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconView.image = UIImage(systemName: icon)
    }

    // MARK: - Public API

    /// 🔵 Circle + number
    func updateSteps(current: Int, goal: Int) {
        valueLabel.text = "\(current)"

        let progress = min(Double(current) / Double(goal), 1.0)
        progressView.setProgress(progress, animated: true)
        progressView.setColor(color(for: progress))
    }

    /// 📊 Mini chart (Steps card only)
    
    func updateChart(values: [Int], progress: Double) {
        guard cardType == .steps else { return }

        let color = color(for: progress)

        miniChartView.update(
            values: values,
            progress: progress,
            color: color
        )
    }

    func updateSubtitle(_ text: String) {
        subtitleLabel.text = text
    }

    // MARK: - Helpers
    private func color(for progress: Double) -> UIColor {
        if progress >= 1 {
            return .systemGreen
        } else if progress > 0.7 {
            return .systemOrange
        } else {
            return .systemBlue
        }
    }

    // MARK: - Touch
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.alpha = 0.6
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.alpha = 1
            self.transform = .identity
        }
    }
}
