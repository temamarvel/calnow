//
//  OnboardingMainView.swift
//  calnow
//
//  Created by Артем Денисов on 17.11.2025.
//

import SwiftUI
import SwiftData

struct OnboardingMainView: View {
    enum Step {
        case healthPermissions
        case profile
    }
    
    @State private var step: Step = .healthPermissions
    
    var body: some View {
        Group {
            switch step {
                case .healthPermissions:
                    OnboardingHealthPermissionsStepView{
                        step = .profile
                    }
                case .profile:
                    OnboardingProfileStepView()
            }
        }
        .animation(.default, value: step)
    }
}
