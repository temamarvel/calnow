//
//  SettingsView.swift
//  calnow
//
//  Created by Артем Денисов on 05.01.2026.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        NavigationStack{
            List{
                NavigationLink("Оформление") {
                    AppearanceView()
                }
                
                NavigationLink("Профиль") {
                    ProfileView()
                }
            }
            .padding(.top, 40)
            .scrollContentBackground(.hidden)
            .appBackground()
            .navigationTitle("Настройки")
        }
    }
}

struct AppearanceView: View {
    
    var body: some View {
        Text("Оформление")
    }
}

struct ProfileView: View {
    
    var body: some View {
        Text("Профиль")
    }
}

#Preview {
    SettingsView()
}
