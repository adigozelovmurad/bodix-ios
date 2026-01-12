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
    private let skeleton = SkeletonView()
    private var didCelebrateGoal = false
    private var isExpanded = false
    private var originalHeight: CGFloat = 100


    


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

    private func playGoalCompletionAnimation() {
        // 🌟 Green glow
        layer.shadowColor = UIColor.systemGreen.cgColor
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
        layer.shadowOffset = .zero

        UIView.animate(withDuration: 0.25, animations: {
            self.layer.shadowRadius = 18
            self.layer.shadowOpacity = 0.45
            self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
        }) { _ in
            UIView.animate(withDuration: 0.25) {
                self.transform = .identity
            }
        }
    }


    // MARK: - UI
    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16
        clipsToBounds = true

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

        [
            iconView,
            titleLabel,
            subtitleLabel,
            valueLabel,
            progressView,
            miniChartView,
            skeleton
        ].forEach {
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
            miniChartView.heightAnchor.constraint(equalToConstant: 32),

            skeleton.topAnchor.constraint(equalTo: topAnchor),
            skeleton.leadingAnchor.constraint(equalTo: leadingAnchor),
            skeleton.trailingAnchor.constraint(equalTo: trailingAnchor),
            skeleton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func configure(title: String, subtitle: String, icon: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        iconView.image = UIImage(systemName: icon)
    }

    // MARK: - Public API

    /// 🔵 Circle + value
    func updateSteps(current: Int, goal: Int) {
        valueLabel.text = "\(current)"

        let progress = min(Double(current) / Double(goal), 1.0)
        let c = color(for: progress)
        progressView.setProgress(progress, animated: true)

        let color = color(for: progress)
        progressView.setColor(c)
        progressView.applyGlow(color: c)

        // 🎉 Goal completed
        if progress >= 1, !didCelebrateGoal {
            didCelebrateGoal = true
            playGoalCompletionAnimation()
        }

        // Reset (sabah üçün)
        if progress < 1 {
            didCelebrateGoal = false
        }
    }


    /// 📊 Mini chart (Steps card only)
   
    func updateChart(
        today: [Int],
        yesterday: [Int],
        progress: Double
    ) {
        guard cardType == .steps else { return }

        let color = color(for: progress)

        miniChartView.update(
            today: today,
            yesterday: yesterday,
            progress: progress,
            color: color
        )
    }

    func toggleExpand() {
        guard cardType == .steps else { return }

        isExpanded.toggle()
        let scale: CGFloat = isExpanded ? 1.03 : 1.0

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.4,
            options: [.curveEaseInOut]
        ) {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.layoutIfNeeded()
        }
    }


    





    func updateSubtitle(_ text: String) {
        subtitleLabel.text = text
    }

    // MARK: - Skeleton
    func showSkeleton() {
        skeleton.alpha = 1
        skeleton.isHidden = false
        bringSubviewToFront(skeleton)
    }

    func hideSkeleton() {
        UIView.animate(withDuration: 0.25) {
            self.skeleton.alpha = 0
        } completion: { _ in
            self.skeleton.stop()
        }
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
