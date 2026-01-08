//
//  StepsManager.swift
//  Bodix
//
//  Created by MURAD on 7.01.2026.
//

import Foundation
import CoreMotion

final class StepsManager {

    // MARK: - Singleton
    static let shared = StepsManager()
    private init() {}

    private let pedometer = CMPedometer()
    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private let goalKey = "dailyStepsGoal"
    private let streakCountKey = "stepsStreakCount"
    private let lastStreakDateKey = "lastStreakDate"

    // MARK: - Notifications
    static let goalDidChangeNotification =
        Notification.Name("StepsGoalDidChange")

    // MARK: - Daily Goal (SINGLE SOURCE OF TRUTH)
    var dailyGoal: Int {
        get {
            let saved = defaults.integer(forKey: goalKey)
            return saved == 0 ? 10_000 : saved
        }
        set {
            defaults.set(newValue, forKey: goalKey)
            NotificationCenter.default.post(
                name: StepsManager.goalDidChangeNotification,
                object: nil
            )
        }
    }

    // MARK: - 🔥 PREWARM (UI FREEZE FIX)
    /// CoreMotion-u əvvəlcədən oyadır (ilk run lag qarşısını alır)
    func prewarm() {
        guard CMPedometer.isStepCountingAvailable() else { return }

        let now = Date()
        let start = Calendar.current.date(byAdding: .minute, value: -1, to: now)!

        pedometer.queryPedometerData(from: start, to: now) { _, _ in
            // intentionally empty – sensor warm-up
        }
    }

    // MARK: - Today Steps
    func fetchTodaySteps(completion: @escaping (Int) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            completion(0)
            return
        }

        let start = Calendar.current.startOfDay(for: Date())

        pedometer.queryPedometerData(from: start, to: Date()) { data, _ in
            DispatchQueue.main.async {
                completion(data?.numberOfSteps.intValue ?? 0)
            }
        }
    }

    // MARK: - Yesterday Steps
    func fetchYesterdaySteps(completion: @escaping (Int) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            completion(0)
            return
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        else {
            completion(0)
            return
        }

        pedometer.queryPedometerData(from: yesterday, to: today) { data, _ in
            DispatchQueue.main.async {
                completion(data?.numberOfSteps.intValue ?? 0)
            }
        }
    }

    // MARK: - Streak Logic
    @discardableResult
    func updateStreakIfNeeded(todaySteps: Int) -> Int {

        let goal = dailyGoal
        let today = Calendar.current.startOfDay(for: Date())

        let lastDate = defaults.object(forKey: lastStreakDateKey) as? Date
        var streak = defaults.integer(forKey: streakCountKey)

        // Goal çatmayıbsa → streak dəyişmir
        guard todaySteps >= goal else {
            return streak
        }

        // Eyni gün artıq hesablanıbsa
        if let lastDate,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return streak
        }

        // Dünən davam edibsə → artır
        if let lastDate,
           let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today),
           Calendar.current.isDate(lastDate, inSameDayAs: yesterday) {
            streak += 1
        } else {
            streak = 1
        }

        defaults.set(streak, forKey: streakCountKey)
        defaults.set(today, forKey: lastStreakDateKey)

        return streak
    }

    // MARK: - Mini Chart (9 bars – safe & smooth)
    func fetchHourlySteps(completion: @escaping ([Int]) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            completion(Array(repeating: 0, count: 9))
            return
        }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())

        pedometer.queryPedometerData(from: start, to: Date()) { data, _ in
            DispatchQueue.main.async {
                let totalSteps = data?.numberOfSteps.intValue ?? 0

                let buckets = 9
                let perBucket = totalSteps / buckets
                let remainder = totalSteps % buckets

                var values = Array(repeating: perBucket, count: buckets)
                if remainder > 0 {
                    values[buckets - 1] += remainder
                }

                completion(values)
            }
        }
    }
}
