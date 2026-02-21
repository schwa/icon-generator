import ArgumentParser
import SwiftUI

/// Corner style for the icon shape
public enum CornerStyle: String, CaseIterable, Sendable, Codable, ExpressibleByArgument {
    /// No rounded corners (square)
    case none
    /// Standard rounded corners (circular arcs)
    case rounded
    /// Continuous/superellipse corners (iOS-style squircle)
    case squircle

    public var roundedCornerStyle: RoundedCornerStyle? {
        switch self {
        case .none:
            return nil
        case .rounded:
            return .circular
        case .squircle:
            return .continuous
        }
    }
}
