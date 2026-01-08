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
    var distance: Double = 0
    var calories: Double = 0
    var goalSteps: Int = 10_000

    var goalProgress: Double {
        min(Double(steps) / Double(goalSteps), 1.0)
    }

    var distanceKm: Double {
        distance / 1000
    }

    var isGoalReached: Bool {
        steps >= goalSteps
    }
}

// MARK: - Steps View Controller
final class StepsViewController: UIViewController {

    // MARK: - Motion
    private let pedometer = CMPedometer()
    private var stepsData = StepsData()

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let circularProgressView = CircularProgressView()

    private let stepsLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedDigitSystemFont(ofSize: 56, weight: .bold)
        l.textAlignment = .center
        l.text = "0"
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        return l
    }()

    private let goalLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()

    private let motivationLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textAlignment = .center
        l.numberOfLines = 2
        l.textColor = .systemBlue
        return l
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

    private let editGoalButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = "Edit Goal"
        config.image = UIImage(systemName: "slider.horizontal.3")
        config.imagePadding = 8
        config.cornerStyle = .medium
        return UIButton(configuration: config)
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        loadSavedGoal()
        observeGoalChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 🔥 Donmanı önləyən əsas hissə
        DispatchQueue.global(qos: .userInitiated).async {
            guard CMPedometer.isStepCountingAvailable() else { return }

            let start = Calendar.current.startOfDay(for: Date())

            self.pedometer.queryPedometerData(from: start, to: Date()) { [weak self] data, _ in
                DispatchQueue.main.async {
                    self?.updateStepsData(with: data)
                }
            }

            self.pedometer.startUpdates(from: start) { [weak self] data, _ in
                DispatchQueue.main.async {
                    self?.updateStepsData(with: data)
                }
            }
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

        let progressContainer = UIView()
        progressContainer.addSubview(circularProgressView)
        progressContainer.addSubview(stepsLabel)
        progressContainer.addSubview(goalLabel)

        let statsStack = UIStackView(arrangedSubviews: [
            distanceCard,
            caloriesCard,
            goalCard
        ])
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually

        [progressContainer, motivationLabel, statsStack, editGoalButton].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        stepsLabel.translatesAutoresizingMaskIntoConstraints = false
        goalLabel.translatesAutoresizingMaskIntoConstraints = false

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

            progressContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            progressContainer.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            progressContainer.widthAnchor.constraint(equalToConstant: 260),
            progressContainer.heightAnchor.constraint(equalToConstant: 260),

            circularProgressView.topAnchor.constraint(equalTo: progressContainer.topAnchor),
            circularProgressView.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor),
            circularProgressView.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            circularProgressView.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),

            stepsLabel.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            stepsLabel.centerYAnchor.constraint(equalTo: progressContainer.centerYAnchor, constant: -8),

            goalLabel.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 4),
            goalLabel.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),

            motivationLabel.topAnchor.constraint(equalTo: progressContainer.bottomAnchor, constant: 20),
            motivationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            motivationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            statsStack.topAnchor.constraint(equalTo: motivationLabel.bottomAnchor, constant: 24),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsStack.heightAnchor.constraint(equalToConstant: 100),

            editGoalButton.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: 24),
            editGoalButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            editGoalButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Data
    private func updateStepsData(with data: CMPedometerData?) {
        guard let data else { return }

        stepsData.steps = data.numberOfSteps.intValue
        stepsData.distance = data.distance?.doubleValue ?? 0
        stepsData.calories = Double(stepsData.steps) * 0.04
        updateUI()
    }

    private func updateUI() {
        stepsLabel.text = formatNumber(stepsData.steps)
        goalLabel.text = "of \(formatNumber(stepsData.goalSteps)) steps"

        circularProgressView.setProgress(stepsData.goalProgress, animated: true)

        let color: UIColor =
            stepsData.goalProgress >= 1 ? .systemGreen :
            stepsData.goalProgress > 0.7 ? .systemOrange : .systemBlue

        circularProgressView.setColor(color)
        motivationLabel.textColor = color

        distanceCard.updateValue(String(format: "%.2f", stepsData.distanceKm))
        caloriesCard.updateValue(String(format: "%.0f", stepsData.calories))
        goalCard.updateValue(formatNumber(stepsData.goalSteps))
    }

    // MARK: - Goal
    private func loadSavedGoal() {
        stepsData.goalSteps = StepsManager.shared.dailyGoal
    }

    private func observeGoalChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(goalDidChange),
            name: StepsManager.goalDidChangeNotification,
            object: nil
        )
    }

    @objc private func goalDidChange() {
        stepsData.goalSteps = StepsManager.shared.dailyGoal
        updateUI()
    }

    @objc private func editGoalTapped() {
        let alert = UIAlertController(
            title: "Daily Steps Goal",
            message: "Set your daily step target",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.placeholder = "10000"
            textField.text = "\(self.stepsData.goalSteps)"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard
                let self,
                let text = alert.textFields?.first?.text,
                let goal = Int(text),
                goal >= 1000
            else {
                return
            }

            // 🔹 Single source of truth
            StepsManager.shared.dailyGoal = goal

            // 🔹 Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        })

        present(alert, animated: true)
    }


    // MARK: - Helpers
    private func formatNumber(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
