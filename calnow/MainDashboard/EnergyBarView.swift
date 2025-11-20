//
//  EnergyBarView.swift
//  calnow
//
//  Created by Артем Денисов on 18.11.2025.
//


import SwiftUI

struct EnergyBarView: View {
    let title: String        // "План" или "Факт"
    let tdee: Double         // полный TDEE
    let bmr: Double          // BMR
    let total: Double        // сколько "использовано" (для плана = tdee, для факта = фактические калории)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            let fullRange = max(tdee, 1) * 1.5
            // Заголовок + цифры
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Всего: \(Int(total)) / \(Int(fullRange)) ккал")
                        .font(.caption.monospacedDigit())

                    Text("BMR: \(Int(bmr)) ккал")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geo in
                let width = geo.size.width
                 // защита от деления на 0

                // доля BMR и доля total от TDEE
                let bmrRatio = min(bmr / fullRange, 1)
                let totalRatio = min(total / fullRange, 1)

                ZStack(alignment: .leading) {
                    // Полная полоса TDEE — фон
                    Capsule()
                        .fill(.thinMaterial)
                        .frame(height: 14)

                    // Заполненная часть total — лёгкий цвет поверх (для факта будет не до конца)
                    Capsule()
                        .fill(Color.accentColor.opacity(0.2))
                        .frame(width: width * totalRatio, height: 14)

                    // BMR — яркая часть слева
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: width * bmrRatio, height: 14)
                }
            }
            .frame(height: 14) // фиксируем высоту GeometryReader
        }
        //.padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview("EnergyBar") {
    VStack(alignment: .leading, spacing: 16) {
        EnergyBarView(
            title: "План на день",
            tdee: 2600,
            bmr: 1700,
            total: 2600
        )
        
        EnergyBarView(
            title: "Факт сейчас",
            tdee: 2600,
            bmr: 1700,
            total: 1850
        )
    }
    .padding()
}
