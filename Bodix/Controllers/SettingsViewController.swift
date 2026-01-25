//
//  SettingsViewController.swift
//  Bodix
//
//  Created by MURAD on 4.01.2026.
//

import UIKit

final class SettingsViewController: UITableViewController {

    // MARK: - Sections
    enum Section: Int, CaseIterable {
        case appearance
        case goal
        case preferences
        case about

        var title: String {
            switch self {
            case .appearance: return "Appearance"
            case .goal: return "Daily Goal"
            case .preferences: return "Preferences"
            case .about: return "About"
            }
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Settings"
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(goalDidChange),
            name: StepsManager.goalDidChangeNotification,
            object: nil
        )
    }

    // MARK: - Table Structure
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .preferences:
            return 2   // Haptic + Distance Unit
        default:
            return 1
        }
    }

    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        Section(rawValue: section)?.title
    }

    // MARK: - Cell
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default

        guard let section = Section(rawValue: indexPath.section) else { return cell }

        var config = cell.defaultContentConfiguration()

        switch section {

        // 🌙 Appearance
        case .appearance:
            config.text = "Dark Mode"

            let toggle = UISwitch()
            toggle.isOn = AppearanceManager.shared.appearance == .dark
            toggle.addAction(
                UIAction { action in
                    let isOn = (action.sender as? UISwitch)?.isOn ?? false
                    AppearanceManager.shared.appearance = isOn ? .dark : .system
                },
                for: .valueChanged
            )

            cell.accessoryView = toggle
            cell.selectionStyle = .none

        // 🎯 Goal
        case .goal:
            config.text = "Daily Step Goal"
            config.secondaryText = "\(StepsManager.shared.dailyGoal) steps"
            cell.accessoryType = .disclosureIndicator

        // ⚙️ Preferences
        case .preferences:

            // 🔔 Haptic
            if indexPath.row == 0 {
                config.text = "Haptic Feedback"
                config.secondaryText = "Vibrations for actions"

                let toggle = UISwitch()
                toggle.isOn = HapticManager.shared.isEnabled
                toggle.addAction(
                    UIAction { action in
                        let isOn = (action.sender as? UISwitch)?.isOn ?? true
                        HapticManager.shared.isEnabled = isOn
                        if isOn { HapticManager.shared.toggle() }
                    },
                    for: .valueChanged
                )

                cell.accessoryView = toggle
                cell.selectionStyle = .none
            }

            // 📏 Distance Unit
            else {
                config.text = "Distance Unit"
                config.secondaryText = StepsManager.shared.distanceUnit.title
                cell.accessoryType = .disclosureIndicator
            }

        // ℹ️ About
        case .about:
            config.text = "About Bodix"
            cell.accessoryType = .disclosureIndicator
        }

        cell.contentConfiguration = config
        return cell
    }

    // MARK: - Selection
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        switch section {
        case .goal:
            openDailyGoal()

        case .preferences:
            if indexPath.row == 1 {
                openDistanceUnitSelector()
            }

        case .about:
            navigationController?.pushViewController(AboutViewController(), animated: true)

        default:
            break
        }
    }

    // MARK: - Distance Unit
    private func openDistanceUnitSelector() {
        let alert = UIAlertController(
            title: "Distance Unit",
            message: "Choose how distance is displayed",
            preferredStyle: .actionSheet
        )

        DistanceUnit.allCases.forEach { unit in
            alert.addAction(
                UIAlertAction(title: unit.title, style: .default) { _ in
                    StepsManager.shared.distanceUnit = unit
                    self.tableView.reloadSections(
                        IndexSet(integer: Section.preferences.rawValue),
                        with: .automatic
                    )
                }
            )
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Goal
    @objc private func goalDidChange() {
        tableView.reloadSections(
            IndexSet(integer: Section.goal.rawValue),
            with: .automatic
        )
    }

    private func openDailyGoal() {
        let alert = UIAlertController(
            title: "Daily Step Goal",
            message: "Set your daily step target",
            preferredStyle: .alert
        )

        alert.addTextField {
            $0.keyboardType = .numberPad
            $0.text = "\(StepsManager.shared.dailyGoal)"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            if let text = alert.textFields?.first?.text,
               let goal = Int(text), goal >= 1000 {
                StepsManager.shared.dailyGoal = goal
                HapticManager.shared.success()
            }
        })

        present(alert, animated: true)
    }
}
