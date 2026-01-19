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
    private let weeklyChartView = WeeklyStepsChartView()
    private let permissionView = StepsPermissionView()
    private var presentedDayVC: DayDetailsViewController?
    private var isPedometerRunning = false
    private var didStartPedometer = false
    private var didReturnFromSettings = false
    private var didHandlePermissionOnce = false
    private var shouldShowPermissionUI = true
    


    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let circularProgressView = CircularProgressView()

    private var brandColor: UIColor {
        UIColor(named: "BrandPrimary") ?? .systemBlue
    }


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
    private lazy var distanceCard = StatsCardView(
        icon: "figure.walk",
        title: "Distance",
        value: "0.0",
        unit: "km",
        color: brandColor
    )


    private lazy var caloriesCard = StatsCardView(
        icon: "flame.fill",
        title: "Calories",
        value: "0",
        unit: "kcal",
        color: brandColor
    )

    private lazy var goalCard = StatsCardView(
        icon: "target",
        title: "Goal",
        value: "10,000",
        unit: "steps",
        color: brandColor
    )

    private let editGoalButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.title = "Edit Goal"
        config.image = UIImage(systemName: "slider.horizontal.3")
        config.imagePadding = 8
        config.cornerStyle = .medium
        return UIButton(configuration: config)
    }()

    private let weeklySummaryTitle: UILabel = {
        let l = UILabel()
        l.text = "This Week"
        l.font = .systemFont(ofSize: 18, weight: .bold)
        return l
    }()

    private lazy var weeklyStepsCard = StatsCardView(
        icon: "figure.walk",
        title: "Steps",
        value: "0",
        unit: "",
        color: .systemBlue
    )

    private lazy var weeklyDistanceCard = StatsCardView(
        icon: "location.fill",
        title: "Distance",
        value: "0.0",
        unit: "km",
        color: .systemIndigo
    )

    private lazy var weeklyCaloriesCard = StatsCardView(
        icon: "flame.fill",
        title: "Calories",
        value: "0",
        unit: "kcal",
        color: .systemOrange
    )


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        loadSavedGoal()
        observeGoalChanges()
        loadWeeklySteps()




        weeklyChartView.onDaySelected = { [weak self] day in
            self?.showDayDetails(day)
        }


    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        print("📐 chart frame:", weeklyChartView.frame)

        if didReturnFromSettings {
            // ✅ Settings-dən qayıdanda dərhal check et
            handlePermissionStateOnAppear()
        } else {
            // ✅ İlk açılışda 0.5s gözlə
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.handlePermissionStateOnAppear()
            }
        }
    }


    private func handlePermissionStateOnAppear() {
        let status = CMPedometer.authorizationStatus()

        // ✅ Flag-ı dərhal reset et
        let wasReturningFromSettings = didReturnFromSettings
        didReturnFromSettings = false

        switch status {

        case .authorized:
            shouldShowPermissionUI = false

            if permissionView.superview != nil {
                permissionView.removeFromSuperview()
            }

            if !didStartPedometer {
                didStartPedometer = true
                startPedometer()
            }

        case .notDetermined:
            showPermissionView()

        case .denied, .restricted:
            showPermissionView(openSettings: true)

        @unknown default:
            break
        }
    }

    // StepsViewController.swift-də showDayDetails metodunu bu kod ilə əvəz edin:

    private func showDayDetails(_ day: DaySteps) {

        let isToday = Calendar.current.isDateInToday(day.date)

        let finalDay: DaySteps

        if isToday {
            // 🔴 Əgər Today-dirsə → həmişə live data göstər
            finalDay = DaySteps(
                date: Date(),
                steps: stepsData.steps,
                distance: stepsData.distance,
                calories: stepsData.calories
            )
        } else {
            finalDay = day
        }

        // Əgər artıq açıq sheet varsa → yalnız update et
        if let existingVC = presentedDayVC {
            existingVC.update(day: finalDay)
            return
        }

        let vc = DayDetailsViewController(day: finalDay)
        presentedDayVC = vc

        vc.modalPresentationStyle = .pageSheet
        vc.presentationController?.delegate = self

        if let sheet = vc.sheetPresentationController {
            let smallId = UISheetPresentationController.Detent.Identifier("small")

            sheet.detents = [
                .custom(identifier: smallId) { _ in 200 },
                .medium()
            ]

            sheet.selectedDetentIdentifier = smallId
            sheet.prefersGrabberVisible = true
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.preferredCornerRadius = 20
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        present(vc, animated: true)
    }


    private func calculateWeeklySummary(from data: [DaySteps]) -> (steps: Int, distance: Double, calories: Double) {
        let totalSteps = data.reduce(0) { $0 + $1.steps }
        let totalDistance = data.reduce(0) { $0 + $1.distance }
        let totalCalories = data.reduce(0) { $0 + $1.calories }
        return (totalSteps, totalDistance, totalCalories)
    }




    

    private func startPedometer() {
        print("🔵 startPedometer called - isPedometerRunning: \(isPedometerRunning), didStartPedometer: \(didStartPedometer)")

        guard !isPedometerRunning else {
            print("⚠️ Pedometer ALREADY running!")
            return
        }

        guard CMPedometer.authorizationStatus() == .authorized else {
            print("⚠️ Not authorized!")
            return
        }

        print("✅ Starting pedometer...")
        isPedometerRunning = true
        didStartPedometer = true

        let start = Calendar.current.startOfDay(for: Date())

        pedometer.queryPedometerData(from: start, to: Date()) { [weak self] data, error in
            if let error = error {
                print("❌ Query error: \(error)")
            }
            DispatchQueue.main.async {
                self?.updateStepsData(with: data)
            }
        }

        pedometer.startUpdates(from: start) { [weak self] data, error in
            if let error = error {
                print("❌ Update error: \(error)")
            }
            DispatchQueue.main.async {
                self?.updateStepsData(with: data)
            }
        }
    }


    deinit {
        pedometer.stopUpdates()
        isPedometerRunning = false
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Steps"
        view.backgroundColor = .systemBackground
        stepsLabel.textColor = .label
        goalLabel.textColor = .secondaryLabel
        navigationController?.navigationBar.prefersLargeTitles = true
        circularProgressView.tintColor = UIColor(named: "BrandPrimary")
        editGoalButton.addTarget(self, action: #selector(editGoalTapped), for: .touchUpInside)
    }



    private func showPermissionView(openSettings: Bool = false) {
        guard shouldShowPermissionUI else { return }

        if permissionView.superview == nil {
            view.addSubview(permissionView)
            permissionView.frame = view.bounds
        }

        permissionView.button.removeTarget(nil, action: nil, for: .allEvents)

        permissionView.button.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }

                if openSettings {
                    self.openSettingsWithConfirmation()
                } else {
                    self.requestInitialPermission()
                }
            },
            for: .touchUpInside
        )
    }



    private func requestInitialPermission() {
        CMPedometer().queryPedometerData(
            from: Date(),
            to: Date()
        ) { _, _ in
            // iOS özü permission alert göstərir
        }
    }



    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.bringSubviewToFront(weeklyChartView)


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

        let weeklySummaryStack = UIStackView(arrangedSubviews: [
            weeklyStepsCard,
            weeklyDistanceCard,
            weeklyCaloriesCard
        ])

        weeklySummaryStack.axis = .horizontal
        weeklySummaryStack.spacing = 12
        weeklySummaryStack.distribution = .fillEqually
        weeklySummaryStack.translatesAutoresizingMaskIntoConstraints = false

        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually

        [progressContainer, motivationLabel, statsStack, editGoalButton,weeklyChartView,weeklySummaryTitle,weeklySummaryStack].forEach {
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
          //  editGoalButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            weeklyChartView.topAnchor.constraint(equalTo: editGoalButton.bottomAnchor, constant: 24),
            weeklyChartView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weeklyChartView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weeklyChartView.heightAnchor.constraint(equalToConstant: 180),
           // weeklyChartView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),

            weeklySummaryTitle.topAnchor.constraint(equalTo: weeklyChartView.bottomAnchor, constant: 24),
            weeklySummaryTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weeklySummaryTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            weeklySummaryStack.topAnchor.constraint(equalTo: weeklySummaryTitle.bottomAnchor, constant: 12),
            weeklySummaryStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            weeklySummaryStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            weeklySummaryStack.heightAnchor.constraint(equalToConstant: 100),

            weeklySummaryStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)

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

    private func loadWeeklySteps() {
        StepsManager.shared.fetchWeeklySteps { [weak self] data in
            guard let self else { return }

            self.weeklyChartView.update(
                data: data,
                goal: StepsManager.shared.dailyGoal,
                brandColor: brandColor
            )

            let summary = self.calculateWeeklySummary(from: data)

            self.weeklyStepsCard.updateValue(formatNumber(summary.steps))
            self.weeklyDistanceCard.updateValue(String(format: "%.1f", summary.distance / 1000))
            self.weeklyCaloriesCard.updateValue(String(format: "%.0f", summary.calories))
        }
    }



    private func updateUI() {
        stepsLabel.text = formatNumber(stepsData.steps)
        goalLabel.text = "of \(formatNumber(stepsData.goalSteps)) steps"

        circularProgressView.setProgress(stepsData.goalProgress, animated: true)

        let brandColor = UIColor(named: "BrandPrimary") ?? .systemBlue

        let color: UIColor =
            stepsData.goalProgress >= 1 ? .systemGreen :
            stepsData.goalProgress > 0.7 ? .systemOrange :
            brandColor

        circularProgressView.setColor(color)
        motivationLabel.textColor = color

        distanceCard.updateValue(String(format: "%.2f", stepsData.distanceKm))
        caloriesCard.updateValue(String(format: "%.0f", stepsData.calories))
        goalCard.updateValue(formatNumber(stepsData.goalSteps))

        
        // 🔄 Əgər açıq sheet varsa və bu GÜN göstərilirsə, onu canlı yenilə
        if let dayVC = presentedDayVC {
            let today = Calendar.current.startOfDay(for: Date())
            let selectedDay = Calendar.current.startOfDay(for: dayVC.day.date)

            if today == selectedDay {
                let liveDay = DaySteps(
                    date: Date(),
                    steps: stepsData.steps,
                    distance: stepsData.distance,
                    calories: stepsData.calories
                )
                dayVC.update(day: liveDay)
            }
        }


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

            NotificationCenter.default.post(
                name: StepsManager.goalDidChangeNotification,
                object: nil
            )

            // 🔹 Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        })

        present(alert, animated: true)
    }


    // MARK: - Helpers


    private func openSettingsWithConfirmation() {
        let alert = UIAlertController(
            title: "Permission Required",
            message: "To track your steps, please allow Motion access in Settings.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            self.didReturnFromSettings = true

            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })


        present(alert, animated: true)
    }


    private func formatNumber(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

}


extension StepsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        weeklyChartView.resetFocus()
        presentedDayVC = nil // 🔥 BU VACİBDİR
    }
}

