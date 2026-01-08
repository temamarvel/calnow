//
//  View+Legacy.swift
//  calnow
//
//  Created by Артем Денисов on 08.01.2026.
//

import SwiftUI

extension View {
    /// Применяет `legacy` только на iOS < 26.
    @ViewBuilder
    func legacyModifiers<LegacyView: View>(
        @ViewBuilder _ legacyView: (Self) -> LegacyView
    ) -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            legacyView(self)
        }
    }
}
