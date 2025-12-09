//
//  FontExtension.swift
//  calnow
//
//  Created by Artem Denisov on 04.12.2025.
//

import SwiftUI

extension Font {
    static func scaledSize(multiplier: CGFloat, relativeTo: UIFont.TextStyle) -> Font {
        let uiFont = UIFont.preferredFont(forTextStyle: relativeTo)
        let baseSize = uiFont.pointSize
        
        return .system(size: baseSize * multiplier)
    }
    
    func scaled(multiplier: CGFloat) -> Font {
        let textStyle: UIFont.TextStyle

        // Сопоставляем SwiftUI Font с UIKit TextStyle
        if self == .largeTitle {
            textStyle = .largeTitle
        } else if self == .title {
            textStyle = .title1
        } else if self == .title2 {
            textStyle = .title2
        } else if self == .title3 {
            textStyle = .title3
        } else if self == .headline {
            textStyle = .headline
        } else if self == .subheadline {
            textStyle = .subheadline
        } else if self == .body {
            textStyle = .body
        } else if self == .callout {
            textStyle = .callout
        } else if self == .caption {
            textStyle = .caption1
        } else if self == .caption2 {
            textStyle = .caption2
        } else if self == .footnote {
            textStyle = .footnote
        } else {
            // fallback — если шрифт кастомный или неизвестный
            textStyle = .body
        }

        let baseSize = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        return .system(size: baseSize * multiplier)
    }
}
