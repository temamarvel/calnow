//
//  ToolbarCapsuleLabel.swift
//  calnow
//
//  Created by Артем Денисов on 09.01.2026.
//


import SwiftUI

struct ToolbarCapsuleLabel: View {
    let title: String
    let systemImage: String

    @ScaledMetric(relativeTo: .callout) private var iconBox: CGFloat = 16

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: systemImage)
                .font(.callout.weight(.semibold))     // единый стиль глифа
                .frame(width: iconBox, height: iconBox, alignment: .center)
        }
        .font(.callout) // единый baseline для текста/лейбла
    }
}
