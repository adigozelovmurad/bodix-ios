//
//   WeeklyStepsChartView.swift
//  Bodix
//
//  Created by MURAD on 14.01.2026.
//

import UIKit

final class WeeklyStepsChartView: UIView {

    private let barCount = 7
    private let maxBarHeight: CGFloat = 100
    private let minBarHeight: CGFloat = 20

    private var barContainers: [UIView] = []
    private var bars: [UIView] = []
    private var dayLabels: [UILabel] = []
    private var stepLabels: [UILabel] = []
    private var heightConstraints: [NSLayoutConstraint] = []
    var onDaySelected: ((DaySteps) -> Void)?
    private var currentData: [DaySteps] = []



    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    private func setupUI() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        isUserInteractionEnabled = true


        let chartStack = UIStackView()
        chartStack.axis = .horizontal
        chartStack.spacing = 8
        chartStack.alignment = .fill
        chartStack.distribution = .fillEqually
        chartStack.isUserInteractionEnabled = true

        addSubview(chartStack)
        chartStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            chartStack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            chartStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            chartStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chartStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])

        for i in 0..<barCount {
            let container = UIView()
            container.backgroundColor = .clear
            container.tag = i
            container.isUserInteractionEnabled = true

            // Step count label (üstdə göstəriləcək - 5.8k)
            let stepLabel = UILabel()
            stepLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            stepLabel.textAlignment = .center
            stepLabel.textColor = .label
            stepLabel.text = ""
            stepLabel.isUserInteractionEnabled = false

            // Bar
            let bar = UIView()
            bar.backgroundColor = .systemGray5
            bar.layer.cornerRadius = 10
            bar.layer.masksToBounds = true
            bar.isUserInteractionEnabled = false

            // Day label (Mon, Tue...)
            let dayLabel = UILabel()
            dayLabel.font = .systemFont(ofSize: 13, weight: .medium)
            dayLabel.textAlignment = .center
            dayLabel.textColor = .secondaryLabel
            dayLabel.text = ""
            dayLabel.isUserInteractionEnabled = false

            container.addSubview(stepLabel)
            container.addSubview(bar)
            container.addSubview(dayLabel)

            // Tap gesture
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleContainerTap(_:)))
            container.addGestureRecognizer(tap)

            stepLabel.translatesAutoresizingMaskIntoConstraints = false
            bar.translatesAutoresizingMaskIntoConstraints = false
            dayLabel.translatesAutoresizingMaskIntoConstraints = false

            let height = bar.heightAnchor.constraint(equalToConstant: minBarHeight)
            height.isActive = true

            NSLayoutConstraint.activate([
                // Step label - üst
                stepLabel.bottomAnchor.constraint(equalTo: bar.topAnchor, constant: -6),
                stepLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

                // Bar - ortada, flexible
                bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                bar.bottomAnchor.constraint(equalTo: dayLabel.topAnchor, constant: -8),

                // Day label - alt
                dayLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                dayLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                dayLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                dayLabel.heightAnchor.constraint(equalToConstant: 18)
            ])

            bars.append(bar)
            barContainers.append(container)
            dayLabels.append(dayLabel)
            stepLabels.append(stepLabel)
            heightConstraints.append(height)
            chartStack.addArrangedSubview(container)
        }
    }

    func update(data: [DaySteps], goal: Int, brandColor: UIColor) {
        guard data.count == barCount else { return }
        self.currentData = data

        let maxSteps = max(data.map { $0.steps }.max() ?? 1, goal)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"

        for i in 0..<barCount {
            let steps = data[i].steps
            let ratio = CGFloat(steps) / CGFloat(maxSteps)
            let height = max(minBarHeight, ratio * maxBarHeight)

            let isToday = Calendar.current.isDateInToday(data[i].date)

            // Gün adı (Mon, Tue...)
            let dayText = dateFormatter.string(from: data[i].date)
            dayLabels[i].text = dayText

            

            // Rəng


            let fadedBrand = brandColor.withAlphaComponent(0.4)

                       var color: UIColor

                       if isToday {
                           color = brandColor
                       } else {
                           color = fadedBrand
                       }

                       


            dayLabels[i].font = isToday ? .systemFont(ofSize: 13, weight: .bold) : .systemFont(ofSize: 13, weight: .medium)
            dayLabels[i].textColor = isToday ? brandColor : .secondaryLabel

            // Üstdəki rəqəm (5.8k formatında)
            stepLabels[i].text = steps > 0 ? formatSteps(steps) : ""
            stepLabels[i].textColor = isToday ? brandColor : .label

            heightConstraints[i].constant = height
            bars[i].backgroundColor = color
            bars[i].alpha = isToday ? 1.0 : 0.6
            

            

        }

        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.3,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            self.layoutIfNeeded()
        }
    }

    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            let k = Double(steps) / 1000.0
            return String(format: "%.1fk", k)
        } else {
            return "\(steps)"
        }
    }

    @objc private func handleContainerTap(_ sender: UITapGestureRecognizer) {
        guard let container = sender.view else { return }

        let index = container.tag
        guard index < currentData.count else { return }

        print("✅ Bar \(index) tapped")

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            for (i, bar) in self.bars.enumerated() {
                if i == index {
                    bar.alpha = 1.0
                    bar.transform = CGAffineTransform(scaleX: 1.08, y: 1.08) // 🔥 fokus
                } else {
                    bar.alpha = 0.4
                    bar.transform = .identity
                }
            }
        }

        // Haptic feedback
        HapticManager.shared.light()


        let selectedDay = currentData[index]
        onDaySelected?(selectedDay)
    }

    func resetFocus() {
        UIView.animate(withDuration: 0.2) {
            for (i, bar) in self.bars.enumerated() {
                let isToday = Calendar.current.isDateInToday(self.currentData[i].date)
                bar.alpha = isToday ? 1.0 : 0.6
                bar.transform = .identity
            }
        }

    }


}
