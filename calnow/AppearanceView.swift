//
//  AppearanceView.swift
//  calnow
//
//  Created by Артем Денисов on 05.01.2026.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
            case .system: return "Системная"
            case .light: return "Светлая"
            case .dark: return "Тёмная"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
        }
    }
}


struct AppearanceView: View {
    
    @AppStorage("app_theme")
    private var theme: AppTheme = .system
    
    var body: some View {
        NavigationStack{
            List{
                Picker("Тема", selection: $theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.title)
                            .tag(theme)
                    }
                }
                .pickerStyle(.inline)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Оформление")
            .appBackground()
        }
    }
}

#Preview {
    AppearanceView()
}
