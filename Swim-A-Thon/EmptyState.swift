//
//  EmptyState.swift
//  Swim-A-Thon
//
//  Created by Ethan Sisbarro on 4/22/26.
//

import SwiftUI

// MARK: - Empty state

struct EmptyState: View {
    let metrics: LayoutMetrics
    @State private var bob: Bool = false
    @State private var shimmer: Bool = false
    @AppStorage("reduceLag") private var reduceLag: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .offset(y: bob ? -4 : 4)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: bob)
                .onAppear { bob = true }
                // NEW: parallax tilt
                .rotation3DEffect(.degrees(bob ? 2 : -2), axis: (x: 0, y: 1, z: 0))
            Text("No swimmers yet")
                .font(metrics.titleFont)
                .overlay {
                    // NEW: gentle shimmer sweep
                    if !reduceLag {
                        ShimmerView()
                            .opacity(shimmer ? 0.35 : 0)
                            .allowsHitTesting(false)
                    }
                }
            Text("Add a swimmer above to start tracking laps.")
                .font(metrics.secondaryFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: metrics.cardCornerRadius)
                .fill(Color(.tertiarySystemBackground))
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).delay(0.4).repeatForever(autoreverses: true)) {
                shimmer = true
            }
        }
        .accessibilityElement(children: .combine)
    }
}
