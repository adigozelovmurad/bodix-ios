//
//   WorkoutViewController.swift
//  Bodix
//
//  Created by MURAD on 4.01.2026.
//

import UIKit

// MARK: - Timer State Model
struct TimerState {
    var totalSeconds: Int
    var remainingSeconds: Int
    var isRunning: Bool = false
    var isPaused: Bool = false

    var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(remainingSeconds) / CGFloat(totalSeconds)
    }
}

// MARK: - Main View Controller
final class WorkoutViewController: UIViewController {

    // MARK: - State
    private var timerState = TimerState(totalSeconds: 60, remainingSeconds: 60)
    private var timer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    // MARK: - UI Components
    private let circularProgressView = CircularProgressView()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.text = "01:00"
        label.font = .monospacedDigitSystemFont(ofSize: 64, weight: .bold)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready to start"
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let startPauseButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = "Start"
        config.baseBackgroundColor = .systemGreen
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        config.buttonSize = .large
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 20, weight: .semibold)
            return outgoing
        }
        button.configuration = config
        return button
    }()

    private let resetButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.gray()
        config.title = "Reset"
        config.cornerStyle = .medium
        config.buttonSize = .large
        button.configuration = config
        return button
    }()

    private let presetsStackView = UIStackView()
    private var presetButtons: [PresetButton] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        setupActions()
        setupNotifications()
        updateUI()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        endBackgroundTask()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Workout Timer"
        view.backgroundColor = .systemBackground

        // Navigation bar
        navigationController?.navigationBar.prefersLargeTitles = true

        // Presets
        let presets = [(title: "30s", seconds: 30),
                       (title: "45s", seconds: 45),
                       (title: "1m", seconds: 60),
                       (title: "2m", seconds: 120)]

        presets.forEach { preset in
            let button = PresetButton(title: preset.title, seconds: preset.seconds)
            button.addTarget(self, action: #selector(presetTapped(_:)), for: .touchUpInside)
            presetButtons.append(button)
        }

        presetsStackView.axis = .horizontal
        presetsStackView.spacing = 12
        presetsStackView.distribution = .fillEqually
        presetButtons.forEach { presetsStackView.addArrangedSubview($0) }
    }

    private func setupLayout() {
        let timerContainer = UIView()
        timerContainer.addSubview(circularProgressView)
        timerContainer.addSubview(timeLabel)
        timerContainer.addSubview(subtitleLabel)

        let buttonsStack = UIStackView(arrangedSubviews: [startPauseButton, resetButton])
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 12

        [timerContainer, presetsStackView, buttonsStack].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        circularProgressView.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Timer container
            timerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            timerContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerContainer.widthAnchor.constraint(equalToConstant: 280),
            timerContainer.heightAnchor.constraint(equalToConstant: 280),

            // Circular progress
            circularProgressView.topAnchor.constraint(equalTo: timerContainer.topAnchor),
            circularProgressView.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor),
            circularProgressView.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor),
            circularProgressView.bottomAnchor.constraint(equalTo: timerContainer.bottomAnchor),

            // Time label
            timeLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: timerContainer.centerYAnchor, constant: -10),
            timeLabel.leadingAnchor.constraint(equalTo: timerContainer.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: timerContainer.trailingAnchor, constant: -20),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: timerContainer.centerXAnchor),

            // Presets
            presetsStackView.topAnchor.constraint(equalTo: timerContainer.bottomAnchor, constant: 40),
            presetsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            presetsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            presetsStackView.heightAnchor.constraint(equalToConstant: 50),

            // Buttons
            buttonsStack.topAnchor.constraint(equalTo: presetsStackView.bottomAnchor, constant: 32),
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            startPauseButton.heightAnchor.constraint(equalToConstant: 56),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupActions() {
        startPauseButton.addTarget(self, action: #selector(startPauseTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // MARK: - Actions
    @objc private func presetTapped(_ sender: PresetButton) {
        guard !timerState.isRunning else { return }

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        timerState.totalSeconds = sender.seconds
        timerState.remainingSeconds = sender.seconds
        timerState.isPaused = false

        updateUI()
        highlightSelectedPreset(sender)
    }

    @objc private func startPauseTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        if timerState.isRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    @objc private func resetTapped() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        stopTimer()
        timerState.remainingSeconds = timerState.totalSeconds
        timerState.isPaused = false
        updateUI()
    }

    // MARK: - Timer Logic
    private func startTimer() {
        guard timerState.remainingSeconds > 0 else { return }

        timerState.isRunning = true
        timerState.isPaused = false

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }

        RunLoop.current.add(timer!, forMode: .common)
        updateUI()
    }

    private func pauseTimer() {
        timerState.isRunning = false
        timerState.isPaused = true
        timer?.invalidate()
        timer = nil
        updateUI()
    }

    private func stopTimer() {
        timerState.isRunning = false
        timerState.isPaused = false
        timer?.invalidate()
        timer = nil
        endBackgroundTask()
    }

    private func tick() {
        guard timerState.remainingSeconds > 0 else {
            timerFinished()
            return
        }

        timerState.remainingSeconds -= 1
        updateUI()
    }

    private func timerFinished() {
        stopTimer()
        timerState.remainingSeconds = 0
        updateUI()

        // Haptic & notification
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        showCompletionAlert()
    }

    // MARK: - UI Updates
    private func updateUI() {
        updateTimeLabel()
        updateButtons()
        updateProgress()
        updateSubtitle()
    }

    private func updateTimeLabel() {
        let minutes = timerState.remainingSeconds / 60
        let seconds = timerState.remainingSeconds % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateButtons() {
        var config = startPauseButton.configuration

        if timerState.isRunning {
            config?.title = "Pause"
            config?.baseBackgroundColor = .systemOrange
        } else if timerState.isPaused {
            config?.title = "Resume"
            config?.baseBackgroundColor = .systemBlue
        } else {
            config?.title = "Start"
            config?.baseBackgroundColor = .systemGreen
        }

        startPauseButton.configuration = config

        // Reset button
        var resetConfig = resetButton.configuration
        resetConfig?.baseForegroundColor = timerState.isRunning || timerState.isPaused ? .systemRed : .secondaryLabel
        resetButton.configuration = resetConfig
        resetButton.isEnabled = timerState.remainingSeconds != timerState.totalSeconds || timerState.isRunning || timerState.isPaused

        // Disable presets during timer
        presetButtons.forEach { $0.isEnabled = !timerState.isRunning }
    }

    private func updateProgress() {
        circularProgressView.setProgress(timerState.progress, animated: true)

        if timerState.remainingSeconds == 0 {
            circularProgressView.setColor(.systemGreen)
        } else if timerState.isRunning {
            circularProgressView.setColor(.systemBlue)
        } else if timerState.isPaused {
            circularProgressView.setColor(.systemOrange)
        } else {
            circularProgressView.setColor(.systemGray)
        }
    }

    private func updateSubtitle() {
        if timerState.remainingSeconds == 0 {
            subtitleLabel.text = "Complete! 🎉"
            subtitleLabel.textColor = .systemGreen
        } else if timerState.isRunning {
            subtitleLabel.text = "Keep going!"
            subtitleLabel.textColor = .systemBlue
        } else if timerState.isPaused {
            subtitleLabel.text = "Paused"
            subtitleLabel.textColor = .systemOrange
        } else {
            subtitleLabel.text = "Ready to start"
            subtitleLabel.textColor = .secondaryLabel
        }
    }

    private func highlightSelectedPreset(_ selectedButton: PresetButton) {
        presetButtons.forEach { button in
            button.isSelected = button == selectedButton
        }
    }

    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: "Time's Up! ⏰",
            message: "Great work! Ready for another round?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Done", style: .cancel) { [weak self] _ in
            self?.resetTapped()
        })

        alert.addAction(UIAlertAction(title: "Restart", style: .default) { [weak self] _ in
            self?.resetTapped()
            self?.startTimer()
        })

        present(alert, animated: true)
    }

    // MARK: - Background Handling
    @objc private func appDidEnterBackground() {
        guard timerState.isRunning else { return }

        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }

    @objc private func appWillEnterForeground() {
        endBackgroundTask()
    }

    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}


final class PresetButton: UIButton {

    let seconds: Int

    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1.0 : 0.5
        }
    }

    init(title: String, seconds: Int) {
        self.seconds = seconds
        super.init(frame: .zero)

        var config = UIButton.Configuration.gray()
        config.title = title
        config.cornerStyle = .medium
        config.baseForegroundColor = .label
        config.baseBackgroundColor = .secondarySystemBackground
        configuration = config

        layer.cornerRadius = 12
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAppearance() {
        var config = configuration

        if isSelected {
            config?.baseBackgroundColor = .systemBlue
            config?.baseForegroundColor = .white
        } else {
            config?.baseBackgroundColor = .secondarySystemBackground
            config?.baseForegroundColor = .label
        }

        configuration = config
    }
}
