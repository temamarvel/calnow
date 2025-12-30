//
//  AppBackgroundModifier.swift
//  calnow
//
//  Created by Артем Денисов on 30.12.2025.
//

import SwiftUI

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func appBackground() -> some View {
        self.modifier(AppBackgroundModifier())
    }
}
