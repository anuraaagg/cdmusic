import SwiftUI

enum T3Color {
    static let surfacePrimary = Color(red: 0.973, green: 0.969, blue: 0.957) // #F8F7F4
    static let textPrimary    = Color(red: 0.031, green: 0.031, blue: 0.031) // #080808
    static let blockWhite     = Color(red: 0.965, green: 0.953, blue: 0.945) // #F6F3F1
    static let blockGrey      = Color(red: 0.88, green: 0.87, blue: 0.86)
    static let labelDark      = Color(red: 0.192, green: 0.192, blue: 0.192) // #313131
    static let labelBright    = Color.white
    static let bgOrange       = Color(red: 0.953, green: 0.286, blue: 0.055) // #F3490E
    static let bgDarkGrey     = Color(red: 0.141, green: 0.137, blue: 0.137) // #242323
    static let blockBlackTop  = Color(red: 0.278, green: 0.271, blue: 0.271)
    static let blockBlackBot  = Color(red: 0.184, green: 0.180, blue: 0.180)
    static let knobFace       = Color(red: 0.94, green: 0.93, blue: 0.91)
    static let knobRing       = Color(red: 0.90, green: 0.89, blue: 0.87)
    static let ledOrange      = Color(red: 0.953, green: 0.286, blue: 0.055)
    static let ledOff         = Color(red: 0.35, green: 0.35, blue: 0.35)
    static let shellLight     = Color(red: 0.90, green: 0.89, blue: 0.87)
    static let shellMid       = Color(red: 0.82, green: 0.81, blue: 0.79)
}

enum T3Font {
    static func header(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    static func labelMedium(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    static func labelSmall(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    static func labelDetail(_ size: CGFloat = 9) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

enum T3Layout {
    static let screenInset: CGFloat = 14
    static let sectionGap: CGFloat = 8
    static let blockGap: CGFloat = 5
    static let blockHeight: CGFloat = 44
    static let headerHeight: CGFloat = 40
    static let knobSize: CGFloat = 118
    static let buttonHalfH: CGFloat = 46
    static let buttonSize: CGFloat = 88
    static let hingeHeight: CGFloat = 8
    static let topPanelRatio: CGFloat = 0.52
    static let dragHandleH: CGFloat = 16
    static let keyCapRadius: CGFloat = 14
}

struct T3KeyCapStyle: ViewModifier {
    var fill: Color
    var cornerRadius: CGFloat = T3Layout.keyCapRadius
    var isPressed: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(isPressed ? 0.06 : 0.14), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white, lineWidth: isPressed ? 2 : 2.5)
            )
            .shadow(
                color: Color.black.opacity(isPressed ? 0.22 : 0.38),
                radius: isPressed ? 4 : 8,
                x: isPressed ? 3 : 6,
                y: isPressed ? 3 : 6
            )
            .offset(y: isPressed ? 2 : 0)
    }
}

extension View {
    func t3KeyCap(fill: Color, cornerRadius: CGFloat = T3Layout.keyCapRadius, isPressed: Bool = false) -> some View {
        modifier(T3KeyCapStyle(fill: fill, cornerRadius: cornerRadius, isPressed: isPressed))
    }
}
