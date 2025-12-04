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
}
