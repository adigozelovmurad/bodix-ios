//
//  DayDetailsViewController.swift
//  Bodix
//
//  Created by MURAD on 19.01.2026.
//

import UIKit

final class DayDetailsViewController: UIViewController {

    var day: DaySteps

    private let titleLabel = UILabel()
    private let stepsValueLabel = UILabel()
    private let distanceValueLabel = UILabel()
    private let caloriesValueLabel = UILabel()

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f
    }()

    init(day: DaySteps) {
        self.day = day
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refreshUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center

        let stepsCard = makeCompactStatCard(
            icon: "figure.walk",
            iconColor: .systemBlue,
            title: "Steps",
            valueLabel: stepsValueLabel
        )

        let distanceCard = makeCompactStatCard(
            icon: "location.fill",
            iconColor: .systemIndigo,
            title: "Distance",
            valueLabel: distanceValueLabel
        )

        let caloriesCard = makeCompactStatCard(
            icon: "flame.fill",
            iconColor: .systemOrange,
            title: "Calories",
            valueLabel: caloriesValueLabel
        )

        let statsStack = UIStackView(arrangedSubviews: [
            stepsCard, distanceCard, caloriesCard
        ])
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually

        let mainStack = UIStackView(arrangedSubviews: [
            titleLabel, statsStack
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statsStack.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    private func makeCompactStatCard(icon: String, iconColor: UIColor, title: String, valueLabel: UILabel) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 12

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = iconColor

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        valueLabel.font = .systemFont(ofSize: 16, weight: .bold)
        valueLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            iconImageView, titleLabel, valueLabel
        ])
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .center

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        return container
    }

    func update(day: DaySteps) {
        self.day = day
        refreshUI()
    }

    private func refreshUI() {
        titleLabel.text = formatter.string(from: day.date)
        stepsValueLabel.text = "\(day.steps)"
        distanceValueLabel.text = StepsManager.shared.distanceUnit.format(distanceInMeters: day.distance)
        caloriesValueLabel.text = "\(Int(round(day.calories))) kcal"

    }
}
