//
//  HealthPermissionsStep.swift
//  calnow
//
//  Created by Артем Денисов on 17.11.2025.
//

import SwiftUI
import SwiftData

struct OnboardingHealthPermissionsStepView: View {
    @EnvironmentObject private var healthKit: HealthKitManager

    @State private var isRequestInProgress = false
    @State private var errorMessage: String?
    
    let onCompleted: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Доступ к Здоровью")
                .font(.largeTitle.bold())

            Text("Приложению нужен доступ к данным активности и калориям из Health, чтобы корректно считать ваши затраты энергии.")
                .multilineTextAlignment(.center)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button {
                Task {
                    await requestPermissions()
                }
            } label: {
                if isRequestInProgress {
                    ProgressView()
                } else {
                    Text("Разрешить доступ в Health")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequestInProgress)

            Button("Продолжить без Health") { }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }

    private func requestPermissions() async {
        errorMessage = nil
        isRequestInProgress = true
        defer { isRequestInProgress = false }

        do {
            // здесь твой реальный запрос к HealthKit
            // например:
            await healthKit.requestAuthorization()
            onCompleted()
        } catch {
            errorMessage = "Не удалось запросить доступ. Попробуйте ещё раз. (\(error.localizedDescription))"
        }
    }
}
