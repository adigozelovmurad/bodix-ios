//
//  StepsViewController.swift
//  Bodix
//
//  Created by MURAD on 4.01.2026.
//

import UIKit
import CoreMotion

// MARK: - Steps Data Model
struct StepsData {
    var steps: Int = 0
    var distance: Double = 0 // meters
    var calories: Double = 0
    var goalSteps: Int = 10000

    var goalProgress: Double {
        return min(Double(steps) / Double(goalSteps), 1.0)
    }

    var distanceKm: Double {
        return distance / 1000.0
    }

    var isGoalReached: Bool {
        return steps >= goalSteps
    }
}

// MARK: - Main View Controller
final class StepsViewController: UIViewController {

    // MARK: - Motion
    private let pedometer = CMPedometer()
    private var stepsData = StepsData()

    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Progress Circle
    private let circularProgressView = CircularProgressView()

    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = .monospacedDigitSystemFont(ofSize: 56, weight: .bold)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private let goalLabel: UILabel = {
        let label = UILabel()
        label.text = "of 10,000 steps"
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let motivationLabel: UILabel = {
        let label = UILabel()
        label.text = "Let's get moving! 🚶‍♂️"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .systemBlue
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    // Stats Cards
    private let distanceCard = StatsCardView(
        icon: "figure.walk",
        title: "Distance",
        value: "0.0",
        unit: "km"
    )

    private let caloriesCard = StatsCardView(
        icon: "flame.fill",
        title: "Calories",
        value: "0",
        unit: "kcal"
    )

    private let goalCard = StatsCardView(
        icon: "target",
        title: "Goal",
        value: "10,000",
        unit: "steps"
    )

    // Goal Settings Button
    private let editGoalButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.gray()
        config.title = "Edit Goal"
        config.image = UIImage(systemName: "slider.horizontal.3")
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.cornerStyle = .medium
        button.configuration = config
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        loadSavedGoal()
        checkAvailability()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(goalDidChange),
            name: StepsManager.goalDidChangeNotification,
            object: nil
        )

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 🔹 Smooth giriş animasiyası
        view.alpha = 0
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 1
        }

        // 🔹 Mövcud logic QALIR
        if CMPedometer.isStepCountingAvailable() {
            requestPermissionAndStart()
        }
    }


    deinit {
        pedometer.stopUpdates()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Steps"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        editGoalButton.addTarget(self, action: #selector(editGoalTapped), for: .touchUpInside)
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Progress circle container
        let progressContainer = UIView()
        progressContainer.addSubview(circularProgressView)
        progressContainer.addSubview(stepsLabel)
        progressContainer.addSubview(goalLabel)

        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        stepsLabel.translatesAutoresizingMaskIntoConstraints = false
        goalLabel.translatesAutoresizingMaskIntoConstraints = false

        // Stats stack
        let statsStack = UIStackView(arrangedSubviews: [distanceCard, caloriesCard, goalCard])
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually

        // Add all to content view
        [progressContainer, motivationLabel, statsStack, editGoalButton, statusLabel].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Progress container
            progressContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            progressContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressContainer.widthAnchor.constraint(equalToConstant: 260),
            progressContainer.heightAnchor.constraint(equalToConstant: 260),

            circularProgressView.topAnchor.constraint(equalTo: progressContainer.topAnchor),
            circularProgressView.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            circularProgressView.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            circularProgressView.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor),

            stepsLabel.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            stepsLabel.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor, constant: -8),
            stepsLabel.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor, constant: 20),
            stepsLabel.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor, constant: -20),

            goalLabel.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 4),
            goalLabel.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),

            // Motivation label
            motivationLabel.topAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: 20),
            motivationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            motivationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            // Stats stack
            statsStack.topAnchor.constraint(equalTo: motivationLabel.bottomAnchor, constant: 24),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsStack.heightAnchor.constraint(equalToConstant: 100),

            // Edit goal button
            editGoalButton.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 24),
            editGoalButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            editGoalButton.widthAnchor.constraint(equalToConstant: 160),
            editGoalButton.heightAnchor.constraint(equalToConstant: 44),

            // Status label
            statusLabel.topAnchor.constraint(equalTo: editGoalButton.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - Availability Check
    private func checkAvailability() {
        guard CMPedometer.isStepCountingAvailable() else {
            statusLabel.text = "⚠️ Step counting not available on this device"
            statusLabel.textColor = .systemRed
            return
        }

        statusLabel.text = "📊 Tracking your activity..."
        statusLabel.textColor = .tertiaryLabel
    }

    // MARK: - Permission & Start Tracking
    private func requestPermissionAndStart() {
        let startOfDay = Calendar.current.startOfDay(for: Date())

        // Query today's data
        pedometer.queryPedometerData(from: startOfDay, to: Date()) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.handleError(error)
                    return
                }

                self.updateStepsData(with: data)
                self.startLiveUpdates(from: startOfDay)
            }
        }
    }

    // MARK: - Live Updates
    private func startLiveUpdates(from startDate: Date) {
        pedometer.startUpdates(from: startDate) { [weak self] data, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.handleError(error)
                    return
                }

                self.updateStepsData(with: data)
            }
        }
    }

    // MARK: - Update Data
    private func updateStepsData(with data: CMPedometerData?) {
        guard let data = data else { return }

        let oldSteps = stepsData.steps
        let wasGoalReached = stepsData.isGoalReached

        stepsData.steps = data.numberOfSteps.intValue
        stepsData.distance = data.distance?.doubleValue ?? 0

        // Calculate calories (rough estimate: 0.04 kcal per step)
        stepsData.calories = Double(stepsData.steps) * 0.04

        updateUI()

        // Check if goal just reached
        if !wasGoalReached && stepsData.isGoalReached {
            celebrateGoalReached()
        }

        // Haptic feedback for milestone steps
        if oldSteps / 1000 != stepsData.steps / 1000 {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }

    // MARK: - UI Updates
    private func updateUI() {
        // Steps label with animation
        UIView.transition(
            with: stepsLabel,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) {
            self.stepsLabel.text = self.formatNumber(self.stepsData.steps)
        }

        // Goal label
        goalLabel.text = "of \(formatNumber(stepsData.goalSteps)) steps"

        // Progress ring
        circularProgressView.setProgress(stepsData.goalProgress, animated: true)

        // Update color based on progress
        if stepsData.isGoalReached {
            circularProgressView.setColor(.systemGreen)
        } else if stepsData.goalProgress > 0.7 {
            circularProgressView.setColor(.systemOrange)
        } else {
            circularProgressView.setColor(.systemBlue)
        }

        // Stats cards
        distanceCard.updateValue(String(format: "%.2f", stepsData.distanceKm))
        caloriesCard.updateValue(String(format: "%.0f", stepsData.calories))
        goalCard.updateValue(formatNumber(stepsData.goalSteps))

        // Motivation message
        updateMotivationMessage()
    }

    private func updateMotivationMessage() {
        let progress = stepsData.goalProgress
        let message: String
        let color: UIColor

        switch progress {
        case 0..<0.1:
            message = "Let's get moving! 🚶‍♂️"
            color = .systemBlue
        case 0.1..<0.3:
            message = "Great start! Keep it up! 💪"
            color = .systemBlue
        case 0.3..<0.5:
            message = "You're on fire! 🔥"
            color = .systemOrange
        case 0.5..<0.7:
            message = "Halfway there! 🎯"
            color = .systemOrange
        case 0.7..<0.9:
            message = "Almost there! Don't stop! 🏃‍♂️"
            color = .systemOrange
        case 0.9..<1.0:
            message = "So close! Final push! 💥"
            color = .systemGreen
        default:
            message = "Goal reached! Amazing! 🎉⭐"
            color = .systemGreen
        }

        motivationLabel.text = message
        motivationLabel.textColor = color
    }

    // MARK: - Goal Management

    private func reloadSteps() {
        // 1️⃣ Yeni goal-u single source-dan oxu
        let newGoal = StepsManager.shared.dailyGoal

        // 2️⃣ StepsData-nı yenilə
        stepsData.goalSteps = newGoal

        // 3️⃣ UI-ni yenilə (circle, label, cards)
        updateUI()
    }

    private func loadSavedGoal() {
        if let savedGoal = UserDefaults.standard.object(forKey: "dailyStepsGoal") as? Int {
            stepsData.goalSteps = savedGoal
            goalCard.updateValue(formatNumber(savedGoal))
        }
    }

    private func saveGoal(_ goal: Int) {
        StepsManager.shared.dailyGoal = goal
    }

    @objc private func goalDidChange() {
        reloadSteps()
    }



    @objc private func editGoalTapped() {
        let alert = UIAlertController(
            title: "Set Daily Goal",
            message: "How many steps do you want to reach today?",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "10000"
            textField.keyboardType = .numberPad
            textField.text = "\(self.stepsData.goalSteps)"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Set Goal", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text,
                  let goal = Int(text),
                  goal > 0 else { return }

            self?.saveGoal(goal)

            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        })

        present(alert, animated: true)
    }

    // MARK: - Celebration
    private func celebrateGoalReached() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        let alert = UIAlertController(
            title: "🎉 Goal Reached!",
            message: "Congratulations! You've reached your daily goal of \(formatNumber(stepsData.goalSteps)) steps!",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Awesome!", style: .default))

        present(alert, animated: true)
    }

    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        let nsError = error as NSError

        if nsError.domain == CMErrorDomain && nsError.code == CMErrorMotionActivityNotAuthorized.rawValue {
            statusLabel.text = "⚠️ Motion & Fitness access denied. Please enable in Settings."
            statusLabel.textColor = .systemOrange
        } else {
            statusLabel.text = "⚠️ \(error.localizedDescription)"
            statusLabel.textColor = .systemRed
        }
    }

    // MARK: - Helpers
    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Circular Progress View (Reusable)

// MARK: - Stats Card View
final class StatsCardView: UIView {

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .systemBlue
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        return label
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

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

    private func setupUI() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 16

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, valueLabel, unitLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }

    func updateValue(_ newValue: String) {
        UIView.transition(
            with: valueLabel,
            duration: 0.3,
            options: .transitionCrossDissolve
        ) {
            self.valueLabel.text = newValue
        }
    }
}
