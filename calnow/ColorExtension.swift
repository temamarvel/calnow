//
//  ColorExtension.swift
//  calnow
//
//  Created by Artem Denisov on 01.12.2025.
//

import SwiftUI

extension Color {
    
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
    
    //static let appBackground = Color("AppBackground")
    
    
    static let sunsetOrange = Color(hex: "#FF7E3E")
    static let sunsetDeep = Color(hex: "#E56A2E")
    static let pacific = Color(hex: "#1C9CA6")
    static let skyAqua = Color(hex: "#8AD8D9")
    static let palm = Color(hex: "#6DAA6E")
    static let sand = Color(hex: "#F4D27A")

    static let bgBase = Color(hex: "#FBFAF7")
    static let bgElevated = Color(hex: "#F5F3EF")
    static let card = Color(hex: "#FFFFFF")
    static let cardSecondary = Color(hex: "#F6F3EB")
    static let bgDark = Color(hex: "#111315")
    static let surfaceDark = Color(hex: "#1A1C1E")
    
    
    // отдельные цвета (удобно переиспользовать)
    static let surfCoral   = Color(hex: "#E86A5B")
    static let surfOrange  = Color(hex: "#FF7E3E")
    static let surfSand    = Color(hex: "#F4D27A")
    static let surfPalm    = Color(hex: "#6DAA6E")
    static let surfPacific = Color(hex: "#1C9CA6")
    
    // сам градиент (массив цветов)
    static let surfProgressGradient: [Color] = [
        .surfCoral,
        .surfOrange,
        .surfSand,
        .surfPalm,
        .surfPacific
    ]
}
