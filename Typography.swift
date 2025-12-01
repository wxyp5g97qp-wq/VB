import SwiftUI

struct Typography {
    let font: Font
    let size: CGFloat
    let lineHeight: CGFloat
}

struct AppFont {

    // MARK: - Lead
    static let lead1 = Typography(
        font: .custom("Helvetica-Bold", size: 32),
        size: 32,
        lineHeight: 30
    )

    static let lead2 = Typography(
        font: .custom("Helvetica-Bold", size: 28),
        size: 28,
        lineHeight: 28
    )

    static let lead3 = Typography(
        font: .custom("Helvetica-Bold", size: 20),
        size: 20,
        lineHeight: 22
    )

    static let lead4 = Typography(
        font: .custom("Helvetica-Bold", size: 20),
        size: 20,
        lineHeight: 22
    )

    // MARK: - Roll
    static let roll1 = Typography(
        font: .custom("Helvetica-Bold", size: 16),
        size: 16,
        lineHeight: 22
    )

    static let roll2 = Typography(
        font: .custom("Helvetica", size: 16),      // регулярная Helvetica
        size: 16,
        lineHeight: 22
    )

    // MARK: - Basic
    static let subtitle = Typography(
        font: .custom("Helvetica-Light", size: 12),
        size: 12,
        lineHeight: 18
    )

    static let date = Typography(
        font: .custom("Helvetica-Light", size: 12),
        size: 12,
        lineHeight: 18
    )

    static let text = Typography(
        font: .custom("Helvetica", size: 12),
        size: 12,
        lineHeight: 18
    )

    static let icon = Typography(
        font: .custom("Helvetica", size: 10),
        size: 10,
        lineHeight: 18
    )
}

extension Text {
    func typography(_ style: Typography) -> some View {
        self.font(style.font)
            .lineSpacing(style.lineHeight - style.size)
    }
}
