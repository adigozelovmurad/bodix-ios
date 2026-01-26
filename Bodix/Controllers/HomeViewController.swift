//
//  HomeViewController.swift
//  Bodix
//
//  Created by MURAD on 4.01.2026.
//

import UIKit

final class HomeViewController: UIViewController {

    // MARK: - Scroll
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var isFirstLoad = true

    // MARK: - Header
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Bodix"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()

    private var brandColor: UIColor {
        UIColor(named: "BrandPrimary") ?? .systemBlue
    }

    // MARK: - Stats
    private let stepsStat = HomeStatView(value: "0", title: "Steps")
    private let distanceStat = HomeStatView(value: "0.00 km", title: "Distance")
    private let caloriesStat = HomeStatView(value: "0 kcal", title: "Calories")

    // MARK: - Cards
    
    private let workoutCard = HomeCardView(
        title: "Weekly Progress",
        subtitle: "View your activity this week",
        icon: "7.calendar"
    )

    private let timerCard = HomeCardView(
        title: "Quick Timer",
        subtitle: "Start rest timer",
        icon: "timer"
    )

    private let stepsCard = HomeCardView(
        title: "Steps Today",
        subtitle: "Track your activity",
        icon: "figure.walk",
        type: .steps
    )

    private var stepsCardHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        dateLabel.text = formattedDate()
        greetingLabel.text = greetingText()
        setupLayout()
        setupActions()
        observeGoalChanges()

        workoutCard.showSkeleton()
        timerCard.showSkeleton()
        stepsCard.showSkeleton()

        titleLabel.textColor = brandColor
        workoutCard.setAccentColor(brandColor)
        timerCard.setAccentColor(brandColor)
        stepsCard.setAccentColor(brandColor)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isFirstLoad {
            isFirstLoad = false
            loadTodayData()
        } else {
            loadTodayData()
        }
    }

    // MARK: - DATA FLOW (TƏK MƏNBƏ)
    private func loadTodayData() {
        let goal = StepsManager.shared.dailyGoal

        StepsManager.shared.fetchTodayStats { [weak self] steps, distance, calories in
            guard let self else { return }

            // 🔹 Top stats
            self.stepsStat.update(value: "\(steps)")
            self.caloriesStat.update(value: "\(Int(round(calories))) kcal")
            self.distanceStat.update(value: StepsManager.shared.distanceUnit.format(distanceInMeters: distance))
            self.loadChartsAndProgress(todaySteps: steps, goal: goal)
        }
    }

    private func loadChartsAndProgress(todaySteps: Int, goal: Int) {
        StepsManager.shared.fetchHourlySteps { [weak self] hourly in
            StepsManager.shared.fetchYesterdaySteps { yesterday in
                guard let self else { return }

                let progress = min(Double(todaySteps) / Double(goal), 1.0)

                // 🔵 Circle
                self.stepsCard.updateSteps(current: todaySteps, goal: goal)

                // 📊 Mini chart
                self.stepsCard.updateChart(
                    today: hourly,
                    yesterday: self.makeYesterdayMock(from: hourly),
                    progress: progress
                )

                // 🔥 Diff + streak
                let diff = todaySteps - yesterday
                let sign = diff >= 0 ? "+" : ""
                let diffText = "\(sign)\(diff) vs yesterday"

                let streak = StepsManager.shared.updateStreakIfNeeded(todaySteps: todaySteps)

                if streak > 0 {
                    self.stepsCard.updateSubtitle("Today • \(diffText) • 🔥 \(streak)d")
                } else {
                    self.stepsCard.updateSubtitle("Today • \(diffText)")
                }

                // Skeleton hide
                self.workoutCard.hideSkeleton()
                self.timerCard.hideSkeleton()
                self.stepsCard.hideSkeleton()
            }
        }
    }

    private func makeYesterdayMock(from today: [Int]) -> [Int] {
        today.map {
            max(0, Int(Double($0) * Double.random(in: 0.7...0.95)))
        }
    }

    // MARK: - Layout
    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [titleLabel, dateLabel, greetingLabel].forEach {
            contentView.addSubview($0)
        }

        let statsStack = UIStackView(arrangedSubviews: [
            stepsStat,
            distanceStat,
            caloriesStat
        ])
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually

        [statsStack, workoutCard, timerCard, stepsCard].forEach {
            contentView.addSubview($0)
        }

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        [titleLabel, dateLabel, greetingLabel, statsStack, workoutCard, timerCard, stepsCard]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        stepsCardHeightConstraint = stepsCard.heightAnchor.constraint(equalToConstant: 100)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            greetingLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
            greetingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            statsStack.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 20),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsStack.heightAnchor.constraint(equalToConstant: 80),

            workoutCard.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 24),
            workoutCard.leadingAnchor.constraint(equalTo: statsStack.leadingAnchor),
            workoutCard.trailingAnchor.constraint(equalTo: statsStack.trailingAnchor),
            workoutCard.heightAnchor.constraint(equalToConstant: 100),

            timerCard.topAnchor.constraint(equalTo: workoutCard.bottomAnchor, constant: 16),
            timerCard.leadingAnchor.constraint(equalTo: workoutCard.leadingAnchor),
            timerCard.trailingAnchor.constraint(equalTo: workoutCard.trailingAnchor),
            timerCard.heightAnchor.constraint(equalToConstant: 100),

            stepsCard.topAnchor.constraint(equalTo: timerCard.bottomAnchor, constant: 16),
            stepsCard.leadingAnchor.constraint(equalTo: workoutCard.leadingAnchor),
            stepsCard.trailingAnchor.constraint(equalTo: workoutCard.trailingAnchor),
            stepsCardHeightConstraint,
            stepsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        timerCard.addTarget(self, action: #selector(openTimer), for: .touchUpInside)
        stepsCard.addTarget(self, action: #selector(openSteps), for: .touchUpInside)
        workoutCard.addTarget(self, action: #selector(openWeeklyProgress), for: .touchUpInside)

    }

    @objc private func openSteps() {
        let collapsedHeight: CGFloat = 100
        let expandedHeight: CGFloat = 160

        let isExpanded = stepsCardHeightConstraint.constant > collapsedHeight
        stepsCardHeightConstraint.constant = isExpanded ? collapsedHeight : expandedHeight

        UIView.animate(
            withDuration: 0.35,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.4,
            options: [.curveEaseInOut]
        ) {
            self.view.layoutIfNeeded()
            self.stepsCard.toggleExpand()
        }

        if isExpanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.tabBarController?.selectedIndex = 2
            }
        }
    }

    @objc private func openTimer() {
        tabBarController?.selectedIndex = 1
    }

    @objc private func openWeeklyProgress() {
        guard let tabBar = tabBarController else { return }

        tabBar.selectedIndex = 2

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if
                let nav = tabBar.viewControllers?[2] as? UINavigationController,
                let stepsVC = nav.viewControllers.first as? StepsViewController
            {
                stepsVC.entryPoint = .weeklyProgress
                stepsVC.highlightWeeklyTitle()
            }
        }
    }



    // MARK: - Goal Observer
    private func observeGoalChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(goalDidChange),
            name: StepsManager.goalDidChangeNotification,
            object: nil
        )
    }

    @objc private func goalDidChange() {
        UIView.animate(withDuration: 0.25) {
            self.stepsCard.alpha = 0.6
        }

        loadTodayData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animate(withDuration: 0.25) {
                self.stepsCard.alpha = 1
            }
        }
    }

    // MARK: - Helpers
    private func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning 👋"
        case 12..<18: return "Good afternoon 💪"
        default: return "Good evening 🌙"
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}
