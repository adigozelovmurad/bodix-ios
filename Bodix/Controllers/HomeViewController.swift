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

    // MARK: - Stats
    private let stepsStat = HomeStatView(value: "0", title: "Steps")
    private let timeStat = HomeStatView(value: "0 min", title: "Workout")
    private let caloriesStat = HomeStatView(value: "0 kcal", title: "Calories")

    // MARK: - Cards
    private let workoutCard = HomeCardView(
        title: "Today Workout",
        subtitle: "No workout started yet",
        icon: "dumbbell"
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

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        dateLabel.text = formattedDate()
        greetingLabel.text = greetingText()
        setupLayout()
        setupActions()
        observeGoalChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTodaySteps()
    }

    // MARK: - Data
    private func loadTodaySteps() {
        Task {
            let goal = StepsManager.shared.dailyGoal

            // ✅ Parallel fetch - daha sürətli
            async let todaySteps = fetchTodayStepsAsync()
            async let hourlyValues = fetchHourlyStepsAsync()
            async let yesterdaySteps = fetchYesterdayStepsAsync()

            let (today, hourly, yesterday) = await (todaySteps, hourlyValues, yesterdaySteps)

            // ✅ Main thread-də UI update
            await updateUI(
                todaySteps: today,
                goal: goal,
                hourlyValues: hourly,
                yesterdaySteps: yesterday
            )
        }
    }

    @MainActor
    private func updateUI(
        todaySteps: Int,
        goal: Int,
        hourlyValues: [Int],
        yesterdaySteps: Int
    ) {
        // 🔹 Top stats
        stepsStat.update(value: "\(todaySteps)")
        let calories = Int(Double(todaySteps) * 0.04)
        caloriesStat.update(value: "\(calories) kcal")

        // 🔹 Progress
        let progress = min(Double(todaySteps) / Double(goal), 1.0)

        // 🔵 Circle
        stepsCard.updateSteps(current: todaySteps, goal: goal)

        // 🎨 Circle ilə EYNİ chart rəngi
//        let chartColor: UIColor =
//            progress >= 1 ? .systemGreen :
//            progress > 0.7 ? .systemOrange :
//            .systemBlue

        // 📊 Mini chart (ARTIQ progress YOX)
        stepsCard.updateChart(
            values: hourlyValues,
            progress: progress
        )


        // 🔥 Yesterday + streak
        let diff = todaySteps - yesterdaySteps
        let sign = diff >= 0 ? "+" : ""
        let diffText = "\(sign)\(diff) vs yesterday"

        let streak = StepsManager.shared.updateStreakIfNeeded(
            todaySteps: todaySteps
        )

        if streak > 0 {
            stepsCard.updateSubtitle(
                "Today • \(diffText) • 🔥 \(streak)d"
            )
        } else {
            stepsCard.updateSubtitle(
                "Today • \(diffText)"
            )
        }
    }


    // MARK: - Async Helpers
    private func fetchTodayStepsAsync() async -> Int {
        await withCheckedContinuation { continuation in
            StepsManager.shared.fetchTodaySteps { steps in
                continuation.resume(returning: steps)
            }
        }
    }

    private func fetchHourlyStepsAsync() async -> [Int] {
        await withCheckedContinuation { continuation in
            StepsManager.shared.fetchHourlySteps { values in
                continuation.resume(returning: values)
            }
        }
    }

    private func fetchYesterdayStepsAsync() async -> Int {
        await withCheckedContinuation { continuation in
            StepsManager.shared.fetchYesterdaySteps { steps in
                continuation.resume(returning: steps)
            }
        }
    }

    private func observeGoalChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(goalDidChange),
            name: StepsManager.goalDidChangeNotification,
            object: nil
        )
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
            timeStat,
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
            stepsCard.heightAnchor.constraint(equalToConstant: 100),
            stepsCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Actions
    private func setupActions() {
        timerCard.addTarget(self, action: #selector(openTimer), for: .touchUpInside)
        stepsCard.addTarget(self, action: #selector(openSteps), for: .touchUpInside)
    }

    @objc private func openSteps() {
        stepsCard.isUserInteractionEnabled = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let vc = StepsViewController()
            vc.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
            self.stepsCard.isUserInteractionEnabled = true
        }
    }


    @objc private func openTimer() {
        tabBarController?.selectedIndex = 1
    }

    @objc private func goalDidChange() {
        loadTodaySteps()
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
