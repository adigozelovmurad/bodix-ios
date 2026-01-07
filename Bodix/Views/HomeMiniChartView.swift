//
//  HomeMiniChartView.swift
//  Bodix
//
//  Created by MURAD on 7.01.2026.
//

import UIKit

final class HomeMiniChartView: UIView {

    private var bars: [UIView] = []

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
        stack.spacing = 4
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
            bar.layer.cornerRadius = 4
            bar.heightAnchor.constraint(equalToConstant: 12).isActive = true
            bars.append(bar)
            stack.addArrangedSubview(bar)
        }
    }

    /// 🔥 ƏSAS FUNKSİYA
    func update(progress: Double, color: UIColor) {
        let clamped = min(max(progress, 0), 1)
        let filledBars = Int(round(clamped * Double(bars.count)))

        for (index, bar) in bars.enumerated() {
            let isActive = index < filledBars

            UIView.animate(withDuration: 0.25) {
                bar.backgroundColor = isActive ? color : .systemGray5
                bar.transform = isActive
                    ? CGAffineTransform(scaleX: 1, y: 1.6)
                    : .identity
            }
        }
    }

}
