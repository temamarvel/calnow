//
//  ToastView.swift
//  calnow
//
//  Created by Артем Денисов on 08.01.2026.
//


import SwiftUI

struct ToastView: View {
    let text: String
    var onDismiss: () -> Void
    @State private var isVisible = true
    
    var body: some View {
        Group {
            if isVisible {
                Text(text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .onAppear {
                        // Автоскрытие через 1.8s
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                            withAnimation { isVisible = false }
                            // Уведомим VM через лёгкую задержку, чтобы завершить анимацию
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onDismiss()
                            }
                        }
                    }
                    .accessibilityLabel(text)
            }
        }
    }
}
