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
        case preferences   // 👈 YENİ
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


    

    // MARK: - Table Data
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }

        switch section {
        case .preferences:
            return 2
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        switch section {
        case .goal:
            openDailyGoal()

        case .about:
            let vc = AboutViewController()
            navigationController?.pushViewController(vc, animated: true)

        default:
            break
        }

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }



    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.accessoryView = nil
        cell.accessoryType = .none
        cell.selectionStyle = .default


        guard let section = Section(rawValue: indexPath.section) else {
            return cell
        }

        var config = cell.defaultContentConfiguration()

        switch section {
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

        case .goal:
            config.text = "Daily Step Goal"
            config.secondaryText = "\(StepsManager.shared.dailyGoal) steps"
            cell.accessoryType = .disclosureIndicator


        case .about:
            config.text = "About Bodix"
            cell.accessoryType = .disclosureIndicator
        

        case .preferences:
            if indexPath.row == 0 {
                config.text = "Haptic Feedback"
                config.secondaryText = "Vibrations for actions"

                let toggle = UISwitch()
                toggle.isOn = HapticManager.shared.isEnabled

                toggle.addAction(
                    UIAction { action in
                        let isOn = (action.sender as? UISwitch)?.isOn ?? true
                        HapticManager.shared.isEnabled = isOn

                        // yalnız ON ediləndə yüngül feedback
                        if isOn {
                            HapticManager.shared.toggle()
                        }
                    },
                    for: .valueChanged
                )


                cell.accessoryView = toggle
                cell.selectionStyle = .none

            } else {
                config.text = "Accent Color"
                config.secondaryText = "Bodix Blue"
                cell.accessoryType = .none
                cell.selectionStyle = .none
            }

        }

        cell.contentConfiguration = config
        return cell
    }

    @objc private func goalDidChange() {
        tableView.reloadSections(IndexSet(integer: Section.goal.rawValue), with: .automatic)
    }



    private func openDailyGoal() {
        let alert = UIAlertController(
            title: "Daily Step Goal",
            message: "Set your daily step target",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.placeholder = "10000"
            textField.text = "\(StepsManager.shared.dailyGoal)"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard
                let text = alert.textFields?.first?.text,
                let goal = Int(text),
                goal >= 1000
            else { return }

            StepsManager.shared.dailyGoal = goal

            NotificationCenter.default.post(
                name: StepsManager.goalDidChangeNotification,
                object: nil
            )

            HapticManager.shared.action()


        })

        present(alert, animated: true)
    }


}
