//
//  SkeletonView.swift
//  Bodix
//
//  Created by MURAD on 11.01.2026.
//

import UIKit

final class SkeletonView: UIView {

    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .systemGray5
        layer.cornerRadius = 10
        clipsToBounds = true

        gradient.colors = [
            UIColor.systemGray5.cgColor,
            UIColor.systemGray4.cgColor,
            UIColor.systemGray5.cgColor
        ]

        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint   = CGPoint(x: 1, y: 0.5)

        layer.addSublayer(gradient)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        startAnimating()
    }

    private func startAnimating() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue   = [1, 1.5, 2]
        animation.duration  = 1.2
        animation.repeatCount = .infinity
        gradient.locations = [0, 0.5, 1]
        gradient.add(animation, forKey: "skeleton")
    }

    func stop() {
        gradient.removeAllAnimations()
    }

}
