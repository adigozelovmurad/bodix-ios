//
//   DistanceUnit.swift
//  Bodix
//
//  Created by MURAD on 25.01.2026.
//

import Foundation

enum DistanceUnit: String, CaseIterable {
    case km
    case miles

    var title: String {
        switch self {
        case .km:
            return "Kilometers (km)"
        case .miles:
            return "Miles (mi)"
        }
    }

    func format(distanceInMeters meters: Double) -> String {
        switch self {
        case .km:
            return String(format: "%.2f km", meters / 1000)
        case .miles:
            return String(format: "%.2f mi", meters / 1609.34)
        }
    }
}
