//
//  HomeMiniChartView.swift
//  Bodix
//
//  Created by MURAD on 7.01.2026.
//
import UIKit

final class HomeMiniChartView: UIView {

    // MARK: - Constants
    private enum Constants {
        static let barCount = 12  // 12 bar = hər 2 saata 1 bar (daha detallı)
        static let maxBarHeight: CGFloat = 38

        static let barSpacing: CGFloat = 2.5  // Çox sıx - uzun görünür
        static let barCornerRadius: CGFloat = 2.5
        static let minBarHeight: CGFloat = 6
        static let animationDuration: TimeInterval = 0.3
        static let animationStagger: TimeInterval = 0.025

        static let pulseScale: CGFloat = 1.15
        static let pulseDuration: TimeInterval = 0.9

    }

    // MARK: - Properties
    private var todayBars: [UIView] = []
    private var yesterdayBars: [UIView] = []
    private var todayHeightConstraints: [NSLayoutConstraint] = []
    private var yesterdayHeightConstraints: [NSLayoutConstraint] = []

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Constants.barSpacing
        stackView.alignment = .bottom
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)

        ])

        for _ in 0..<Constants.barCount {
            let container = createBarContainer()
            stackView.addArrangedSubview(container)
        }
    }

    private func createBarContainer() -> UIView {
        let container = UIView()

        // Yesterday bar (background)
        let yesterdayBar = UIView()
        yesterdayBar.backgroundColor = .systemGray5
        yesterdayBar.layer.cornerRadius = Constants.barCornerRadius
        yesterdayBar.layer.masksToBounds = true
        yesterdayBar.translatesAutoresizingMaskIntoConstraints = false

        // Today bar (foreground)
        let todayBar = UIView()
        todayBar.backgroundColor = .systemBlue
        todayBar.layer.cornerRadius = Constants.barCornerRadius
        todayBar.layer.masksToBounds = true
        todayBar.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(yesterdayBar)
        container.addSubview(todayBar)

        let yesterdayHeight = yesterdayBar.heightAnchor.constraint(equalToConstant: Constants.minBarHeight)
        let todayHeight = todayBar.heightAnchor.constraint(equalToConstant: Constants.minBarHeight)

        NSLayoutConstraint.activate([
            yesterdayBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            yesterdayBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            yesterdayBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            yesterdayHeight,

            todayBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            todayBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            todayBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            todayHeight
        ])

        yesterdayBars.append(yesterdayBar)
        todayBars.append(todayBar)
        yesterdayHeightConstraints.append(yesterdayHeight)
        todayHeightConstraints.append(todayHeight)

        return container
    }

    // MARK: - Helpers
    private func currentHourIndex() -> Int {
        let hour = Calendar.current.component(.hour, from: Date())
        let index = hour / 2  // Hər 2 saat = 1 bar
        return min(max(index, 0), Constants.barCount - 1)
    }

    private func calculateBarHeight(value: Int, maxValue: Int) -> CGFloat {
        guard maxValue > 0 else { return Constants.minBarHeight }
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(Constants.minBarHeight, ratio * Constants.maxBarHeight)
    }

    private func determineBarColor(
        at index: Int,
        activeIndex: Int,
        filledBars: Int,
        baseColor: UIColor
    ) -> UIColor {

        if index > activeIndex {
            return .systemGray6
        }

        if index == activeIndex {
            return baseColor
        }

        if index < filledBars {
            return baseColor
        }

        return baseColor.withAlphaComponent(0.25)
    }


    // MARK: - Public API
    func update(
        today: [Int],
        yesterday: [Int],
        progress: Double,
        color: UIColor
    ) {
        UIView.performWithoutAnimation {
            self.layoutIfNeeded()
        }

        // 🔁 RESET previous animations (VERY IMPORTANT)
        todayBars.forEach {
            $0.layer.removeAllAnimations()
            $0.transform = .identity
            $0.alpha = 1
        }

        yesterdayBars.forEach {
            $0.layer.removeAllAnimations()
            $0.transform = .identity
            $0.alpha = 1
        }


        guard today.count == Constants.barCount,
              yesterday.count == Constants.barCount else {
            assertionFailure("Invalid array count. Expected \(Constants.barCount), got today:\(today.count) yesterday:\(yesterday.count)")
            return
        }

        let maxValue = max(
            today.max() ?? 1,
            yesterday.max() ?? 1,
            1
        )

        let activeIndex = currentHourIndex()

        let filledBars = min(
            Int(progress * Double(Constants.barCount)),
            Constants.barCount - 1
        )

        pulseBar(at: activeIndex)



        for index in 0..<Constants.barCount {
            let todayHeight = calculateBarHeight(value: today[index], maxValue: maxValue)
            let yesterdayHeight = calculateBarHeight(value: yesterday[index], maxValue: maxValue)

            let barColor = determineBarColor(
                at: index,
                activeIndex: activeIndex,
                filledBars: filledBars,
                baseColor: color
            )

            animateBar(
                at: index,
                todayHeight: todayHeight,
                yesterdayHeight: yesterdayHeight,
                color: barColor
            )
        }

        // 🔥 GOAL PROGRESS BAR – TƏK PULSE
        if filledBars > 0 {
            let pulseIndex = min(filledBars - 1, Constants.barCount - 1)
            pulse(bar: todayBars[pulseIndex])
        }


    }

    private func animateBar(
        at index: Int,
        todayHeight: CGFloat,
        yesterdayHeight: CGFloat,
        color: UIColor
    ) {
        guard index < todayBars.count else { return }

        let isActiveHour = index == currentHourIndex()

        UIView.animate(
            withDuration: Constants.animationDuration,
            delay: Double(index) * Constants.animationStagger,
            options: [.curveEaseOut],
            animations: {
                self.todayBars[index].backgroundColor = color
                self.todayHeightConstraints[index].constant = todayHeight
                self.yesterdayHeightConstraints[index].constant = yesterdayHeight
                self.layoutIfNeeded()


            },
            completion: { _ in
                guard isActiveHour else { return }

                // 🔵 Pulse effect (yalnız cari saat)
                UIView.animate(
                    withDuration: 0.6,
                    delay: 0,
                    options: [.autoreverse, .repeat, .allowUserInteraction],
                    animations: {
                        self.todayBars[index].transform =
                            CGAffineTransform(scaleX: 1.12, y: 1.12)
                        self.todayBars[index].alpha = 0.85
                    }
                )
            }
        )
    }


    private func pulseBar(at index: Int) {
        guard index < todayBars.count else { return }

        let bar = todayBars[index]

        bar.layer.removeAllAnimations()

        UIView.animate(
            withDuration: Constants.pulseDuration,
            delay: 0,
            options: [.autoreverse, .repeat, .curveEaseInOut],
            animations: {
                bar.transform = CGAffineTransform(scaleX: Constants.pulseScale, y: 1.0)
            }
        )
    }

    private func pulse(bar: UIView) {
        UIView.animate(withDuration: 0.15, animations: {
            bar.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { _ in
            UIView.animate(withDuration: 0.15) {
                bar.transform = .identity
            }
        }
    }


}
