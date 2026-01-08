//
//  HomeMiniChartView.swift
//  Bodix
//
//  Created by MURAD on 7.01.2026.
//

import UIKit

final class HomeMiniChartView: UIView {

    private var bars: [UIView] = []
    private var heightConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 3
        stack.alignment = .bottom
        stack.distribution = .fillEqually

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        for _ in 0..<9 {
            let bar = UIView()
            bar.backgroundColor = .systemGray5
            bar.layer.cornerRadius = 2

            let heightConstraint = bar.heightAnchor.constraint(equalToConstant: 6)
            heightConstraint.isActive = true
            heightConstraints.append(heightConstraint)

            bars.append(bar)
            stack.addArrangedSubview(bar)
        }
    }

    func update(values: [Int], progress: Double, color: UIColor) {
        guard values.count == bars.count else { return }

        let maxValue = max(values.max() ?? 1, 1)

        for (i, value) in values.enumerated() {
            let ratio = CGFloat(value) / CGFloat(maxValue)
            let height = max(6, ratio * 28)

            let newColor = i < Int(progress * Double(bars.count)) ? color : .systemGray5

            UIView.animate(withDuration: 0.25, delay: Double(i) * 0.015) {
                self.bars[i].backgroundColor = newColor
                self.heightConstraints[i].constant = height
                self.layoutIfNeeded()
            }
        }
    }
}
