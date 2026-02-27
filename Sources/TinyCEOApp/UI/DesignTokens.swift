import AppKit
import SwiftUI

enum TinyTokens {
    enum ColorToken {
        static let bgPopover = Color.dynamic(light: 0xFFFFFF, dark: 0x242220)
        static let bgCell = Color.dynamic(light: 0xF5F3F0, dark: 0x2C2A28)
        static let bgWarning = Color.dynamic(light: 0xFFF7EC, dark: 0x2A2116)
        static let bgDanger = Color.dynamic(light: 0xFFF0EE, dark: 0x2E1818)

        static let textPrimary = Color.dynamic(light: 0x1C1C1E, dark: 0xF2F0ED)
        static let textSecondary = Color.dynamic(light: 0x636366, dark: 0x98989D)
        static let borderDefault = Color.dynamic(light: 0xE5E5EA, dark: 0x3A3A3C)
        static let borderWarning = Color.dynamic(light: 0xFF9F0A, dark: 0xFFD60A)
        static let borderDanger = Color.dynamic(light: 0xFF3B30, dark: 0xFF453A)

        static let statusHealthy = Color.dynamic(light: 0x30D158, dark: 0x30D158)
        static let statusWarning = Color.dynamic(light: 0xFF9F0A, dark: 0xFFD60A)
        static let statusDanger = Color.dynamic(light: 0xFF3B30, dark: 0xFF453A)

        static let kpiCash = Color.dynamic(light: 0x1C1C1E, dark: 0xF2F0ED)
        static let kpiRunway = Color.dynamic(light: 0x1C1C1E, dark: 0xF2F0ED)
        static let kpiReputation = Color.dynamic(light: 0x5856D6, dark: 0x7D7AFF)
        static let kpiHealth = Color.dynamic(light: 0x25A244, dark: 0x30D158)
        static let kpiTechDebt = Color.dynamic(light: 0xE6780C, dark: 0xFF9F0A)
    }

    enum Size {
        static let popoverWidth: CGFloat = 360
        static let popoverMinWidth: CGFloat = 300
        static let kpiCellHeight: CGFloat = 56
        static let officeRowHeight: CGFloat = 40
    }
}

private extension Color {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return NSColor(hex: isDark ? dark : light)
            }
        )
    }
}

private extension NSColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(srgbRed: red, green: green, blue: blue, alpha: 1.0)
    }
}
