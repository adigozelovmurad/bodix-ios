//
//  StepsManager.swift
//  Bodix
//
//  Created by MURAD on 7.01.2026.
//

import Foundation
import CoreMotion


enum GoalChangeType {
    case increased
    case decreased
}


final class StepsManager {

    // MARK: - Singleton
    static let shared = StepsManager()
    private init() {}

    private let pedometer = CMPedometer()
    private let defaults = UserDefaults.standard
    private let caloriesPerStep: Double = 0.04


    var wasGoalJustUpdated: Bool = false
    var goalChangeType: GoalChangeType?


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
            let oldGoal = dailyGoal

            defaults.set(newValue, forKey: goalKey)

            // 🔵 Goal change context
            wasGoalJustUpdated = true
            goalChangeType = newValue > oldGoal ? .increased : .decreased

            NotificationCenter.default.post(
                name: StepsManager.goalDidChangeNotification,
                object: nil
            )
        }
    }

    func fetchTodaySteps(completion: @escaping (Int) -> Void) {
        fetchTodayStats { steps, _, _ in
            completion(steps)
        }
    }

    func calculateCalories(from steps: Int) -> Double {
        Double(steps) * caloriesPerStep
    }



    func fetchWeeklySteps(completion: @escaping ([DaySteps]) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            completion([])
            return
        }



        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var results: [DaySteps] = []
        let group = DispatchGroup()

        for i in (0..<7).reversed() {
            group.enter()

            guard
                let start = calendar.date(byAdding: .day, value: -i, to: today),
                let end = calendar.date(byAdding: .day, value: 1, to: start)
            else {
                group.leave()
                continue
            }

            pedometer.queryPedometerData(from: start, to: end) { data, _ in
                let steps = data?.numberOfSteps.intValue ?? 0
                let distance = data?.distance?.doubleValue ?? 0
                let calories = self.calculateCalories(from: steps) 


                results.append(
                    DaySteps(
                        date: start,
                        steps: steps,
                        distance: distance,
                        calories: calories
                    )
                )
                group.leave()
            }
        }

        // 🔴 BURA MÜTLƏQ FOR-DAN SONRA OLMALIDIR
        group.notify(queue: .main) {
            completion(results.sorted { $0.date < $1.date })
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
    func fetchTodayStats(completion: @escaping (_ steps: Int, _ distance: Double, _ calories: Double) -> Void) {
        let start = Calendar.current.startOfDay(for: Date())

        pedometer.queryPedometerData(from: start, to: Date()) { data, error in
            guard let data else {
                DispatchQueue.main.async {
                    completion(0, 0, 0)
                }
                return
            }

            let steps = data.numberOfSteps.intValue
            let distance = data.distance?.doubleValue ?? 0
            let calories = self.calculateCalories(from: steps)

            DispatchQueue.main.async {
                completion(steps, distance, calories)
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


        // MARK: - Mini Chart (12 bars - hər 2 saat)
        func fetchHourlySteps(completion: @escaping ([Int]) -> Void) {
            guard CMPedometer.isStepCountingAvailable() else {
                completion(Array(repeating: 0, count: 12))
                return
            }

            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)

            var hourlyData: [Int] = Array(repeating: 0, count: 12)
            let group = DispatchGroup()

            // Hər 2 saatlıq interval üçün data fetch et
            for i in 0..<12 {
                group.enter()

                let startHour = i * 2
                let endHour = startHour + 2

                guard let start = calendar.date(byAdding: .hour, value: startHour, to: startOfDay),
                      let end = calendar.date(byAdding: .hour, value: endHour, to: startOfDay)
                else {
                    group.leave()
                    continue
                }

                // Gələcək saatları fetch etmə
                if start > now {
                    hourlyData[i] = 0
                    group.leave()
                    continue
                }

                let queryEnd = min(end, now)

                pedometer.queryPedometerData(from: start, to: queryEnd) { data, _ in
                    hourlyData[i] = data?.numberOfSteps.intValue ?? 0
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(hourlyData)
            }
        }
    }


